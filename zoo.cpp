#define ZOO_BUILD
#include "zoo.h"
#include <cmath>
#include <cstdio>
#include <cstring>

namespace zoo {

int Animal::s_alive = 0;

Animal::Animal(const char* n, Vec2 p) : pos_(p), hunger_(50) {
  strncpy_s(name_, n, sizeof(name_) - 1);
  ++s_alive;
}
Animal::~Animal() {
  --s_alive;
  std::printf("[zoo] %s destroyed\n", name_);
}
const char* Animal::name() const { return name_; }
void Animal::feed(int c) { hunger_ = hunger_ - c < 0 ? 0 : hunger_ - c; }
int Animal::hunger() const { return hunger_; }
Vec2 Animal::position() const { return pos_; }
Mood Animal::mood() const { return hunger_ > 70 ? Mood::Grumpy : Mood::Happy; }
void Animal::tick(float dt) { hunger_ += (int)(dt * 10); }
void Animal::move(Vec2 d) { pos_.x += d.x; pos_.y += d.y; }
void Animal::move(float dx, float dy) { move(Vec2{dx, dy}); }
int Animal::alive_count() { return s_alive; }

Penguin::Penguin(const char* n, Vec2 p) : Animal(n, p), slide_timer_(0) {}
Mood Penguin::mood() const {
  return slide_timer_ > 0 ? Mood::Happy : Animal::mood();
}
void Penguin::tick(float dt) {
  Animal::tick(dt);
  if (slide_timer_ > 0) slide_timer_ -= dt;
}
void Penguin::slide(Vec2 dir, float s) {
  move(dir.x * s, dir.y * s);
  slide_timer_ = 2.0f;
}

Lion::Lion(const char* n, Vec2 p, int db) : Animal(n, p), roar_db_(db) {}
Mood Lion::mood() const { return hunger_ > 30 ? Mood::Grumpy : Mood::Sleepy; }
void Lion::tick(float dt) {
  Animal::tick(dt * 2);
  move(dt * 3, 0);  // lions wander
}

Zoo::Zoo() : animals_{}, count_(0), listener_(nullptr) {}
Zoo::~Zoo() {
  for (int i = 0; i < count_; ++i) delete animals_[i];
}
void Zoo::add(Animal* a) { if (count_ < 16) animals_[count_++] = a; }
Animal* Zoo::get(int i) const { return i < count_ ? animals_[i] : nullptr; }
int Zoo::count() const { return count_; }
void Zoo::set_listener(IZooListener* l) { listener_ = l; }
void Zoo::feed_all(int c) {
  for (int i = 0; i < count_; ++i) {
    animals_[i]->feed(c);
    if (listener_) listener_->on_fed(animals_[i], c);
  }
}
void Zoo::simulate(float dt, int steps) {
  for (int s = 0; s < steps; ++s)
    for (int i = 0; i < count_; ++i) {
      Animal* a = animals_[i];
      a->tick(dt);
      Vec2 p = a->position();
      if (std::fabs(p.x) > 10 && listener_ &&
          !listener_->on_escape_attempt(a, p))
        a->move(-p.x, 0);  // dragged back to the center
    }
}
Vec2 Zoo::centroid() const {
  Vec2 c{0, 0};
  for (int i = 0; i < count_; ++i) {
    Vec2 p = animals_[i]->position();
    c.x += p.x; c.y += p.y;
  }
  if (count_) { c.x /= count_; c.y /= count_; }
  return c;
}

float distance(const Vec2& a, const Vec2& b) {
  return std::hypot(a.x - b.x, a.y - b.y);
}
float distance(const Animal& a, const Animal& b) {
  return distance(a.position(), b.position());
}
Animal* make_animal(const char* kind, const char* name) {
  if (std::strcmp(kind, "penguin") == 0) return new Penguin(name, {0, 0});
  if (std::strcmp(kind, "lion") == 0) return new Lion(name, {0, 0}, 110);
  return nullptr;
}

}  // namespace zoo
