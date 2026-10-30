package main

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:math"

LEVEL :: #config(LEVEL, 7)

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
		check(approx(distance(a, b), 5), "distance(Vec2, Vec2) == 5")
		check(approx(distance(b, b), 0), "distance to self == 0")

		p := make_animal("penguin", "pingu")
		l := make_animal("lion", "leo")
		bad := make_animal("unicorn", "nope")
		check(p != nil, "make_animal(penguin) != nil")
		check(l != nil, "make_animal(lion) != nil")
		check(bad == nil, "make_animal(unicorn) == nil")
		check(
			approx(distance(p^, l^), 0),
			"distance(Animal, Animal) == 0 (both at origin)",
		)
		// leaked on purpose; destructors come in level 4
	}
}

// ---------------------------------------------------------------- level 2
when LEVEL >= 2 {
	test_level2 :: proc() {
		section("Level 2: non-virtual + static members")

		before := Animal_alive_count()
		a := make_animal("penguin", "a")
		b := make_animal("penguin", "b")
		expect(Animal_alive_count() - before, 2, "alive_count += 2")

		Animal_move(a, Vec2{3, 4})
		check(approx(distance(a^, b^), 5), "move(Vec2) moved by (3,4)")

		Animal_move(a, -3, -4)
		check(approx(distance(a^, b^), 0), "move(float,float) moved back")

		Animal_move(b, 0, 2.5)
		check(approx(distance(a^, b^), 2.5), "overloads not swapped")
	}
}

// ---------------------------------------------------------------- level 3
when LEVEL >= 3 {
	test_level3 :: proc() {
		section("Level 3: layout + constructors")

		// MSVC x64: two vptrs, no tail-padding reuse for derived classes
		expect(size_of(Animal), 64, "size_of(Animal)")
		expect(offset_of(Animal, _animal_vfptr), 0, "Animal.vt @ 0")
		expect(offset_of(Animal, _ifeedable_vfptr), 8, "Animal.vt_feedable @ 8")
		expect(offset_of(Animal, name_), 16, "Animal.name @ 16")
		expect(offset_of(Animal, pos_), 48, "Animal.pos @ 48")
		expect(offset_of(Animal, hunger_), 56, "Animal.hunger @ 56")
		expect(size_of(Penguin), 72, "size_of(Penguin)")
		expect(offset_of(Penguin, slide_timer_), 64, "Penguin.slide_timer @ 64")
		expect(size_of(Lion), 72, "size_of(Lion)")
		expect(offset_of(Lion, roar_db_), 64, "Lion.roar_db @ 64")
		expect(size_of(Zoo), 144, "size_of(Zoo)")
		expect(offset_of(Zoo, count_), 128, "Zoo.count @ 128")
		expect(offset_of(Zoo, listener_), 136, "Zoo.listener @ 136")

		before := Animal_alive_count()

		p: Penguin
		ret := Penguin_ctor(&p, "stacky", Vec2{1, 2})
		check(ret == &p, "ctor returns this")
		check(p._animal_vfptr != nil && p._ifeedable_vfptr != nil, "ctor filled both vptrs")
		expect(string(cstring(&p.name_[0])), "stacky", "name_ copied")
		check(vec_approx(p.pos_, Vec2{1, 2}), "pos_ == (1,2)")
		expect(p.hunger_, 50, "hunger_ == 50")
		check(approx(p.slide_timer_, 0), "slide_timer_ == 0")

		l: Lion
		Lion_ctor(&l, "simba", Vec2{-1, 0}, 99)
		expect(l.roar_db_, 99, "roar_db_ == 99")
		check(p._animal_vfptr != l._animal_vfptr, "Penguin and Lion have different vtables")

		expect(Animal_alive_count() - before, 2, "alive_count += 2")
		p->dtor()
		l->dtor()
		expect(Animal_alive_count(), before, "dtors decremented alive_count")
	}
}

// ---------------------------------------------------------------- level 4
when LEVEL >= 4 {
	test_level4 :: proc() {
		section("Level 4: vtable calls")

		before := Animal_alive_count()
		p := make_animal("penguin", "pingu")
		l := make_animal("lion", "leo")

		expect(string(p->name()), "pingu", "vt.name()")

		pos: Vec2 = {99, 99}
		r := p->position(&pos)
		check(r == &pos, "position() returns hidden ret ptr")
		check(vec_approx(pos, Vec2{0, 0}), "position() == (0,0)")

		expect(p->mood(), Mood.Happy, "penguin mood Happy @ hunger 50")
		expect(l->mood(), Mood.Grumpy, "lion mood Grumpy @ hunger 50")

		p->tick(3) // hunger += 30
		expect(p.hunger_, 80, "penguin tick(3) -> hunger 80")
		expect(p->mood(), Mood.Grumpy, "penguin Grumpy @ hunger 80")

		l->tick(1) // hunger += 20, x += 3
		expect(l.hunger_, 70, "lion tick doubles dt")
		l->position(&pos)
		check(vec_approx(pos, Vec2{3, 0}), "lion wandered to (3,0)")

		p->dtor({.Free}) // scalar deleting dtor: destruct + free
		l->dtor({.Free})
		expect(Animal_alive_count(), before, "destroy(1) freed both")
	}
}

// ---------------------------------------------------------------- level 5
when LEVEL >= 5 {
	test_level5 :: proc() {
		section("Level 5: multiple inheritance")

		l := make_animal("lion", "leo")
		defer l->dtor({.Free})

		feedable := rawptr(uintptr(l) + uintptr(offset_of(Animal, _ifeedable_vfptr)))
		fvt := l._ifeedable_vfptr

		expect(fvt.hunger(auto_cast feedable), 50, "IFeedable::hunger() via subobject")
		fvt.feed(auto_cast feedable, 20)
		expect(l.hunger_, 30, "IFeedable::feed() adjusted this correctly")
		expect(l->mood(), Mood.Sleepy, "lion Sleepy @ hunger 30")

		fvt.feed(auto_cast feedable, 1000)
		expect(l.hunger_, 0, "hunger clamps at 0")
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

	test_on_fed :: proc "c" (self: ^IZooListener, who: ^INamed, cal: i32) {
		context = runtime.default_context()
		t := (^Test_Listener)(self)
		t.fed += 1
		t.cal_total += int(cal)
	}

	test_on_escape :: proc "c" (
		self: ^IZooListener,
		who: ^INamed,
		pos: Vec2,
	) -> bool {
		context = runtime.default_context()
		t := (^Test_Listener)(self)
		a := (^Animal)(who) // INamed* is at offset 0 of Animal
		t.escapes += 1
		n := string(a->name())
		copy(t.escapee_name[:], n)
		return false // veto!
	}

	test_listener_vt := IZooListener_vftable {
		on_fed            = test_on_fed,
		on_escape_attempt = test_on_escape,
	}

	test_level6 :: proc() {
		section("Level 6: Odin implements a C++ interface")

		before := Animal_alive_count()

		z: Zoo
		Zoo_ctor(&z)
		expect(Zoo_count(&z), 0, "empty zoo")

		Zoo_add(&z, make_animal("penguin", "pingu"))
		Zoo_add(&z, make_animal("lion", "leo"))
		expect(Zoo_count(&z), 2, "count == 2")
		check(Zoo_get(&z, 5) == nil, "get(out of range) == nil")

		lst := Test_Listener{_izoolistener_vfptr = &test_listener_vt}
		Zoo_set_listener(&z, &lst)
		check(z.listener_ == &lst.base, "listener stored")

		Zoo_feed_all(&z, 10)
		expect(lst.fed, 2, "on_fed called twice")
		expect(lst.cal_total, 20, "calories passed through")

		// lion: x = 3, 6, 9, 12 -> veto -> 0, 3
		Zoo_simulate(&z, 1, 5)
		expect(lst.escapes, 1, "one escape attempt")
		expect(
			string(cstring(&lst.escapee_name[0])),
			"leo",
			"escapee name via INamed in callback",
		)

		c: Vec2
		Zoo_centroid(&z, &c)
		check(vec_approx(c, Vec2{1.5, 0}), "centroid == (1.5, 0)")

		Zoo_dtor(&z)
		expect(Animal_alive_count(), before, "Zoo dtor deleted animals")
	}
}

// ---------------------------------------------------------------- level 7
when LEVEL >= 7 {
	test_level7 :: proc() {
		section("Level 7: polished API")

		before := Animal_alive_count()

		l := (^Lion)(make_animal("lion", "leo"))
		expect(Lion_roar_db(l), 110, "roar_db read by offset")
		expect(l->name(), "leo", "animal_name wrapper")
		l->feed(25)
		expect(l.hunger_, 25, "animal_feed hides this-adjust")
		l->dtor()

		p := (^Penguin)(make_animal("penguin", "pingu"))
		Penguin_slide(p, Vec2{1, 0}, 4)
		pos:Vec2
		check(vec_approx(p->position(&pos)^, Vec2{4, 0}), "slide(dir, 4)")
		Penguin_slide(p, Vec2{0, 1}) // default strength
		check(vec_approx(p->position(&pos)^, Vec2{4, 1}), "default strength 1")
		check(approx(p.slide_timer_, 2), "slide_timer set to 2")
		p.hunger_ = 99
		expect(p->mood(), Mood.Happy, "sliding penguin is Happy anyway")
		p->dtor()

		{
			z: Zoo
			Zoo_ctor(&z)
			defer Zoo_dtor(&z)
			Zoo_add(&z, make_animal("penguin", "a"))
			Zoo_add(&z, make_animal("lion", "b"))
			expect(Animal_alive_count() - before, 2, "scoped zoo populated")
		}
		expect(Animal_alive_count(), before, "deferred_out cleaned up zoo")
	}
}

// ---------------------------------------------------------------- main
harness :: proc() -> bool {
	fmt.printf("zoo harness, LEVEL = %d\n", LEVEL)
	when LEVEL == 0 {
		fmt.println("Nothing to test. Use: odin run . -define:LEVEL=1")
		return true
	}
	when LEVEL >= 1 {test_level1()}
	when LEVEL >= 2 {test_level2()}
	when LEVEL >= 3 {test_level3()}
	when LEVEL >= 4 {test_level4()}
	when LEVEL >= 5 {test_level5()}
	when LEVEL >= 6 {test_level6()}
	when LEVEL >= 7 {test_level7()}

	fmt.printf("\n%d passed, %d failed\n", g_pass, g_fail)
	if g_fail > 0 do return false
	return true
}
