#pragma once
#include <cstdint>

#ifdef ZOO_BUILD
#define ZOO_API __declspec(dllexport)
#else
#define ZOO_API __declspec(dllimport)
#endif

namespace zoo {

struct Vec2 {
  float x, y;
};

enum class Mood : uint8_t { Happy, Grumpy, Sleepy };

// ---- Interfaces ----
struct ZOO_API INamed {
  virtual ~INamed() = default;
  virtual const char* name() const = 0;
};

struct ZOO_API IFeedable {
  virtual void feed(int calories) = 0;
  virtual int hunger() const = 0;
};

// Callback interface: YOU implement this in Odin
struct ZOO_API IZooListener {
  virtual void on_fed(INamed* who, int calories) = 0;
  virtual bool on_escape_attempt(INamed* who, Vec2 pos) = 0;
};

// ---- Base class (multiple inheritance!) ----
class ZOO_API Animal : public INamed, public IFeedable {
public:
  Animal(const char* name, Vec2 pos);
  ~Animal() override;

  const char* name() const override;
  void feed(int calories) override;
  int hunger() const override;

  virtual Vec2 position() const;  // returns struct by value
  virtual Mood mood() const;
  virtual void tick(float dt);

  void move(Vec2 delta);          // non-virtual, overloaded
  void move(float dx, float dy);

  static int alive_count();

protected:
  char name_[32];
  Vec2 pos_;
  int hunger_;
  static int s_alive;
};

class ZOO_API Penguin : public Animal {
public:
  Penguin(const char* name, Vec2 pos);
  Mood mood() const override;
  void tick(float dt) override;
  void slide(Vec2 dir, float strength = 1.0f);
private:
  float slide_timer_;
};

class ZOO_API Lion : public Animal {
public:
  Lion(const char* name, Vec2 pos, int roar_db);
  Mood mood() const override;
  void tick(float dt) override;
  int roar_db() const { return roar_db_; }  // inline: NOT exported!
private:
  int roar_db_;
};

// ---- Container ----
class ZOO_API Zoo {
public:
  Zoo();
  ~Zoo();

  void add(Animal* a);            // Zoo takes ownership
  Animal* get(int index) const;
  int count() const;

  void set_listener(IZooListener* l);
  void feed_all(int calories);
  void simulate(float dt, int steps);

  Vec2 centroid() const;          // struct return from member fn

private:
  Animal* animals_[16];
  int count_;
  IZooListener* listener_;
};

// Free functions, some overloaded
ZOO_API float distance(const Vec2& a, const Vec2& b);
ZOO_API float distance(const Animal& a, const Animal& b);
ZOO_API Animal* make_animal(const char* kind, const char* name);

}  // namespace zoo
