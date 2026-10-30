package main

foreign import _zoo_lib "zoo.lib"

Vec2::struct{
   x,y:f32
}

Mood::enum u8{
   Happy,Grumpy,Sleepy
}

IFeedable::struct{
   feed:proc"c"(self:rawptr,cal:i32),
   hunger:proc"c"(self:rawptr)->i32
}

IZooListener_VTable::struct{
   on_fed:proc"c"(self:^IZooListener,who:rawptr,cal:i32),
   on_escape_attempt:proc"c"(self:^IZooListener,who:rawptr,pos:Vec2)->bool,
}

IZooListener::struct{
   vt:^IZooListener_VTable
}

Animal::struct{
   vt:^Animal_VTable,
   vt_feedable:^IFeedable,
   name:[32]u8,
   pos:Vec2,
   hunger:i32,
   _:[4]byte
}

Animal_VTable::struct{
   destroy:proc"c"(self:^Animal,flags:u32)->rawptr,
   name:proc"c"(self:^Animal)->cstring,
   position:proc"c"(self:^Animal,ret:^Vec2)->^Vec2,
   mood:proc"c"(self:^Animal)->Mood,
   tick:proc"c"(self:^Animal,dt:f32)
}

Penguin::struct{
   using base:Animal,
   slide_timer:f32
}

Lion::struct{
   using base:Animal,
   roar_db:i32
}

Zoo::struct{
   animals:[16]^Animal,
   count:i32,
   listener:^IZooListener
}

@(default_calling_convention="c")
foreign _zoo_lib{
   @(link_name="?distance@zoo@@YAMAEBUVec2@1@0@Z")
   distance_vec::proc(a,b:^Vec2)->f32 ---
   @(link_name="?distance@zoo@@YAMAEBVAnimal@1@0@Z")
   distance_animal::proc(a,b:^Animal)->f32 ---
   @(link_name="?make_animal@zoo@@YAPEAVAnimal@1@PEBD0@Z")
   make_animal::proc(kind,name:cstring)->^Animal ---
   @(link_name="?move@Animal@zoo@@QEAAXUVec2@2@@Z")
   animal_move_vec::proc(self:^Animal,d:Vec2) ---
   @(link_name="?move@Animal@zoo@@QEAAXMM@Z")
   animal_move_xy::proc(self:^Animal,dx,dy:f32) ---
   @(link_name="?alive_count@Animal@zoo@@SAHXZ")
   animal_alive_count::proc()->i32 ---
   @(link_name="??0Penguin@zoo@@QEAA@PEBDUVec2@1@@Z")
   penguin_ctor::proc(self:^Penguin,name:cstring,pos:Vec2)->^Penguin ---
   @(link_name="??0Lion@zoo@@QEAA@PEBDUVec2@1@H@Z")
   lion_ctor::proc(self:^Lion,name:cstring,pos:Vec2,db:i32)->^Lion ---
   @(link_name="??1Animal@zoo@@UEAA@XZ")
   animal_dtor::proc(self:^Animal) ---
   @(link_name="??0Zoo@zoo@@QEAA@XZ")
   zoo_ctor::proc(self:^Zoo)->^Zoo ---
   @(link_name="??1Zoo@zoo@@QEAA@XZ")
   zoo_dtor::proc(self:^Zoo) ---
   @(link_name="?add@Zoo@zoo@@QEAAXPEAVAnimal@2@@Z")
   zoo_add::proc(self:^Zoo,a:^Animal) ---
   @(link_name="?get@Zoo@zoo@@QEBAPEAVAnimal@2@H@Z")
   zoo_get::proc(self:^Zoo,index:i32)->^Animal ---
   @(link_name="?count@Zoo@zoo@@QEBAHXZ")
   zoo_count::proc(self:^Zoo)->i32 ---
   @(link_name="?set_listener@Zoo@zoo@@QEAAXPEAUIZooListener@2@@Z")
   zoo_set_listener::proc(self:^Zoo,l:^IZooListener) ---
   @(link_name="?feed_all@Zoo@zoo@@QEAAXH@Z")
   zoo_feed_all::proc(self:^Zoo,cal:i32) ---
   @(link_name="?simulate@Zoo@zoo@@QEAAXMH@Z")
   zoo_simulate::proc(self:^Zoo,dt:f32,steps:i32) ---
   @(link_name="?centroid@Zoo@zoo@@QEBA?AUVec2@2@XZ")
   zoo_centroid::proc(self:^Zoo,ret:^Vec2)->^Vec2 ---
   @(link_name="?slide@Penguin@zoo@@QEAAXUVec2@2@M@Z")
   _penguin_slide::proc(self:^Penguin,dir:Vec2,strength:f32) ---
}

distance::proc{
   distance_vec,
   distance_animal
}

animal_move::proc{
   animal_move_vec,
   animal_move_xy
}

animal_name::proc(a:^Animal)->string{
   return string(a.vt.name(a))
}

animal_position::proc(a:^Animal)->Vec2{
   ret:Vec2
   a.vt.position(a,&ret)
   return ret
}

animal_feed::proc(a:^Animal,cal:i32){
   a.vt_feedable.feed(&a.vt_feedable,cal)
}

animal_destroy::proc(a:^Animal){
   a.vt.destroy(a,1)
}

lion_roar_db::proc(l:^Lion)->i32{
   return l.roar_db
}

penguin_slide::proc(p:^Penguin,dir:Vec2,strength:f32=1){
   _penguin_slide(p,dir,strength)
}

@private zoo_destroy::proc(z:^Zoo){
   zoo_dtor(z)
   free(z)
}

@(deferred_out=zoo_destroy)
zoo_scoped::proc()->^Zoo{
   z:=new(Zoo)
   zoo_ctor(z)
   return z
}
