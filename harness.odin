package main

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:math"

LEVEL :: #config(LEVEL, 0)

// ---------------------------------------------------------------- helpers
g_pass, g_fail: int

check :: proc(cond: bool, what: string, loc := #caller_location) {
	if cond {
		g_pass += 1
		fmt.printf("  [ok]   %s\n", what)
	} else {
		g_fail += 1
		fmt.printf("  [FAIL] %s  (%v)\n", what, loc)
	}
}

expect :: proc(
	got, want: $T,
	what: string,
	loc := #caller_location,
) where intrinsics.type_is_comparable(T) {
	if got == want {
		g_pass += 1
		fmt.printf("  [ok]   %s\n", what)
	} else {
		g_fail += 1
		fmt.printf("  [FAIL] %s: got %v, want %v  (%v)\n", what, got, want, loc)
	}
}

approx :: proc(a, b: f32, eps: f32 = 1e-4) -> bool {
	return math.abs(a - b) < eps
}

vec_approx :: proc(a, b: Vec2) -> bool {
	return approx(a.x, b.x) && approx(a.y, b.y)
}

section :: proc(name: string) {
	fmt.printf("\n== %s ==\n", name)
}

// ---------------------------------------------------------------- level 1
when LEVEL >= 1 {
	test_level1 :: proc() {
		section("Level 1: free functions")

		a, b := Vec2{0, 0}, Vec2{3, 4}
		check(approx(distance_vec(&a, &b), 5), "distance(Vec2, Vec2) == 5")
		check(approx(distance_vec(&b, &b), 0), "distance to self == 0")

		p := make_animal("penguin", "pingu")
		l := make_animal("lion", "leo")
		bad := make_animal("unicorn", "nope")
		check(p != nil, "make_animal(penguin) != nil")
		check(l != nil, "make_animal(lion) != nil")
		check(bad == nil, "make_animal(unicorn) == nil")
		check(
			approx(distance_animal(p, l), 0),
			"distance(Animal, Animal) == 0 (both at origin)",
		)
		// leaked on purpose; destructors come in level 4
	}
}

// ---------------------------------------------------------------- level 2
when LEVEL >= 2 {
	test_level2 :: proc() {
		section("Level 2: non-virtual + static members")

		before := animal_alive_count()
		a := make_animal("penguin", "a")
		b := make_animal("penguin", "b")
		expect(animal_alive_count() - before, 2, "alive_count += 2")

		animal_move_vec(a, Vec2{3, 4})
		check(approx(distance_animal(a, b), 5), "move(Vec2) moved by (3,4)")

		animal_move_xy(a, -3, -4)
		check(approx(distance_animal(a, b), 0), "move(float,float) moved back")

		animal_move_xy(b, 0, 2.5)
		check(approx(distance_animal(a, b), 2.5), "overloads not swapped")
	}
}

// ---------------------------------------------------------------- level 3
when LEVEL >= 3 {
	test_level3 :: proc() {
		section("Level 3: layout + constructors")

		// MSVC x64: two vptrs, no tail-padding reuse for derived classes
		expect(size_of(Animal), 64, "size_of(Animal)")
		expect(offset_of(Animal, vt), 0, "Animal.vt @ 0")
		expect(offset_of(Animal, vt_feedable), 8, "Animal.vt_feedable @ 8")
		expect(offset_of(Animal, name), 16, "Animal.name @ 16")
		expect(offset_of(Animal, pos), 48, "Animal.pos @ 48")
		expect(offset_of(Animal, hunger), 56, "Animal.hunger @ 56")
		expect(size_of(Penguin), 72, "size_of(Penguin)")
		expect(offset_of(Penguin, slide_timer), 64, "Penguin.slide_timer @ 64")
		expect(size_of(Lion), 72, "size_of(Lion)")
		expect(offset_of(Lion, roar_db), 64, "Lion.roar_db @ 64")
		expect(size_of(Zoo), 144, "size_of(Zoo)")
		expect(offset_of(Zoo, count), 128, "Zoo.count @ 128")
		expect(offset_of(Zoo, listener), 136, "Zoo.listener @ 136")

		before := animal_alive_count()

		p: Penguin
		ret := penguin_ctor(&p, "stacky", Vec2{1, 2})
		check(ret == &p, "ctor returns this")
		check(p.vt != nil && p.vt_feedable != nil, "ctor filled both vptrs")
		expect(string(cstring(&p.name[0])), "stacky", "name_ copied")
		check(vec_approx(p.pos, Vec2{1, 2}), "pos_ == (1,2)")
		expect(p.hunger, 50, "hunger_ == 50")
		check(approx(p.slide_timer, 0), "slide_timer_ == 0")

		l: Lion
		lion_ctor(&l, "simba", Vec2{-1, 0}, 99)
		expect(l.roar_db, 99, "roar_db_ == 99")
		check(p.vt != l.vt, "Penguin and Lion have different vtables")

		expect(animal_alive_count() - before, 2, "alive_count += 2")
		animal_dtor(&p)
		animal_dtor(&l)
		expect(animal_alive_count(), before, "dtors decremented alive_count")
	}
}

// ---------------------------------------------------------------- level 4
when LEVEL >= 4 {
	test_level4 :: proc() {
		section("Level 4: vtable calls")

		before := animal_alive_count()
		p := make_animal("penguin", "pingu")
		l := make_animal("lion", "leo")

		expect(string(p.vt.name(p)), "pingu", "vt.name()")

		pos: Vec2 = {99, 99}
		r := p.vt.position(p, &pos)
		check(r == &pos, "position() returns hidden ret ptr")
		check(vec_approx(pos, Vec2{0, 0}), "position() == (0,0)")

		expect(p.vt.mood(p), Mood.Happy, "penguin mood Happy @ hunger 50")
		expect(l.vt.mood(l), Mood.Grumpy, "lion mood Grumpy @ hunger 50")

		p.vt.tick(p, 3) // hunger += 30
		expect(p.hunger, 80, "penguin tick(3) -> hunger 80")
		expect(p.vt.mood(p), Mood.Grumpy, "penguin Grumpy @ hunger 80")

		l.vt.tick(l, 1) // hunger += 20, x += 3
		expect(l.hunger, 70, "lion tick doubles dt")
		l.vt.position(l, &pos)
		check(vec_approx(pos, Vec2{3, 0}), "lion wandered to (3,0)")

		p.vt.destroy(p, 1) // scalar deleting dtor: destruct + free
		l.vt.destroy(l, 1)
		expect(animal_alive_count(), before, "destroy(1) freed both")
	}
}

// ---------------------------------------------------------------- level 5
when LEVEL >= 5 {
	test_level5 :: proc() {
		section("Level 5: multiple inheritance")

		l := make_animal("lion", "leo")
		defer l.vt.destroy(l, 1)

		feedable := rawptr(uintptr(l) + uintptr(offset_of(Animal, vt_feedable)))
		fvt := l.vt_feedable

		expect(fvt.hunger(feedable), 50, "IFeedable::hunger() via subobject")
		fvt.feed(feedable, 20)
		expect(l.hunger, 30, "IFeedable::feed() adjusted this correctly")
		expect(l.vt.mood(l), Mood.Sleepy, "lion Sleepy @ hunger 30")

		fvt.feed(feedable, 1000)
		expect(l.hunger, 0, "hunger clamps at 0")
	}
}

// ---------------------------------------------------------------- level 6
when LEVEL >= 6 {
	Test_Listener :: struct {
		using base:   IZooListener,
		fed:          int,
		cal_total:    int,
		escapes:      int,
		escapee_name: [32]u8,
	}

	test_on_fed :: proc "c" (self: ^IZooListener, who: rawptr, cal: i32) {
		context = runtime.default_context()
		t := (^Test_Listener)(self)
		t.fed += 1
		t.cal_total += int(cal)
	}

	test_on_escape :: proc "c" (
		self: ^IZooListener,
		who: rawptr,
		pos: Vec2,
	) -> bool {
		context = runtime.default_context()
		t := (^Test_Listener)(self)
		a := (^Animal)(who) // INamed* is at offset 0 of Animal
		t.escapes += 1
		n := string(a.vt.name(a))
		copy(t.escapee_name[:], n)
		return false // veto!
	}

	test_listener_vt := IZooListener_VTable {
		on_fed            = test_on_fed,
		on_escape_attempt = test_on_escape,
	}

	test_level6 :: proc() {
		section("Level 6: Odin implements a C++ interface")

		before := animal_alive_count()

		z: Zoo
		zoo_ctor(&z)
		expect(zoo_count(&z), 0, "empty zoo")

		zoo_add(&z, make_animal("penguin", "pingu"))
		zoo_add(&z, make_animal("lion", "leo"))
		expect(zoo_count(&z), 2, "count == 2")
		check(zoo_get(&z, 5) == nil, "get(out of range) == nil")

		lst := Test_Listener{vt = &test_listener_vt}
		zoo_set_listener(&z, &lst)
		check(z.listener == &lst.base, "listener stored")

		zoo_feed_all(&z, 10)
		expect(lst.fed, 2, "on_fed called twice")
		expect(lst.cal_total, 20, "calories passed through")

		// lion: x = 3, 6, 9, 12 -> veto -> 0, 3
		zoo_simulate(&z, 1, 5)
		expect(lst.escapes, 1, "one escape attempt")
		expect(
			string(cstring(&lst.escapee_name[0])),
			"leo",
			"escapee name via INamed in callback",
		)

		c: Vec2
		zoo_centroid(&z, &c)
		check(vec_approx(c, Vec2{1.5, 0}), "centroid == (1.5, 0)")

		zoo_dtor(&z)
		expect(animal_alive_count(), before, "Zoo dtor deleted animals")
	}
}

// ---------------------------------------------------------------- level 7
when LEVEL >= 7 {
	test_level7 :: proc() {
		section("Level 7: polished API")

		before := animal_alive_count()

		l := (^Lion)(make_animal("lion", "leo"))
		expect(lion_roar_db(l), 110, "roar_db read by offset")
		expect(animal_name(l), "leo", "animal_name wrapper")
		animal_feed(l, 25)
		expect(l.hunger, 25, "animal_feed hides this-adjust")
		animal_destroy(l)

		p := (^Penguin)(make_animal("penguin", "pingu"))
		penguin_slide(p, Vec2{1, 0}, 4)
		check(vec_approx(animal_position(p), Vec2{4, 0}), "slide(dir, 4)")
		penguin_slide(p, Vec2{0, 1}) // default strength
		check(vec_approx(animal_position(p), Vec2{4, 1}), "default strength 1")
		check(approx(p.slide_timer, 2), "slide_timer set to 2")
		p.hunger = 99
		expect(p.vt.mood(p), Mood.Happy, "sliding penguin is Happy anyway")
		animal_destroy(p)

		{
			z := zoo_scoped()
			zoo_add(z, make_animal("penguin", "a"))
			zoo_add(z, make_animal("lion", "b"))
			expect(animal_alive_count() - before, 2, "scoped zoo populated")
		}
		expect(animal_alive_count(), before, "deferred_out cleaned up zoo")
	}
}

// ---------------------------------------------------------------- main
main :: proc() {
	fmt.printf("zoo harness, LEVEL = %d\n", LEVEL)
	when LEVEL == 0 {
		fmt.println("Nothing to test. Use: odin run . -define:LEVEL=1")
		return
	}
	when LEVEL >= 1 {test_level1()}
	when LEVEL >= 2 {test_level2()}
	when LEVEL >= 3 {test_level3()}
	when LEVEL >= 4 {test_level4()}
	when LEVEL >= 5 {test_level5()}
	when LEVEL >= 6 {test_level6()}
	when LEVEL >= 7 {test_level7()}

	fmt.printf("\n%d passed, %d failed\n", g_pass, g_fail)
	if g_fail > 0 do runtime.exit(1)
}
