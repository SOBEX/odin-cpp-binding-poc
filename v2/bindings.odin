package main

foreign import _zoo_lib "../zoo.lib"

Scalar_Deleting_Destructor_Flag::enum u32{
   Free=0,
   Vector=1
}

Scalar_Deleting_Destructor_Flags::bit_set[Scalar_Deleting_Destructor_Flag;u32]

Vec2::struct{
   x:f32,
   y:f32
}

Mood::enum u8{
   Happy,Grumpy,Sleepy
}

INamed::struct{
   using _inamed_vfptr:^INamed_vftable
}

INamed_vftable::struct{
   dtor:proc"c"(this:^INamed,flags:Scalar_Deleting_Destructor_Flags={})->rawptr,
   name:proc"c"(this:^INamed)->cstring
}

IFeedable::struct{
   using _ifeedable_vfptr:^IFeedable_vftable
}

IFeedable_vftable::struct{
   feed:proc"c"(this:^IFeedable,calories:i32),
   hunger:proc"c"(this:^IFeedable)->i32
}

IZooListener::struct{
   using _izoolistener_vfptr:^IZooListener_vftable
}

IZooListener_vftable::struct{
   on_fed:proc"c"(this:^IZooListener,who:^INamed,calories:i32),
   on_escape_attempt:proc"c"(this:^IZooListener,who:^INamed,pos:Vec2)->bool,
}

Animal::struct{
   using _:struct #raw_union{
      #subtype _inamed:INamed,
      using _animal_vfptr:^Animal_vftable
   },
   using _ifeedable:IFeedable,
   name_:[32]u8,
   pos_:Vec2,
   hunger_:i32,
   _:[4]byte
}

Animal_vftable::struct{
   using _inamed_vftable:INamed_vftable,
   position:proc"c"(this:^Animal,sret:^Vec2)->^Vec2,
   mood:proc"c"(this:^Animal)->Mood,
   tick:proc"c"(this:^Animal,dt:f32)
}

Penguin::struct{
   using base:Animal,
   slide_timer_:f32,
   _:[4]byte
}

Lion::struct{
   using base:Animal,
   roar_db_:i32,
   _:[4]byte
}

Zoo::struct{
   animals_:[16]^Animal,
   count_:i32,
   listener_:^IZooListener
}

@(default_calling_convention="c")
foreign _zoo_lib{
   @(link_name="??2@YAPEAX_K@Z")
   _new::proc(u64)->rawptr ---
   @(link_name="??3@YAXPEAX_K@Z")
   _delete::proc(rawptr,u64) ---
   @(link_name="??_V@YAXPEAX_K@Z")
   _delete_vector::proc(rawptr,u64) ---
   @(link_name="??0Animal@zoo@@QEAA@AEBV01@@Z")
   Animal_cctor::proc(this,other:^Animal)->^Animal ---
   @(link_name="??0Animal@zoo@@QEAA@PEBDUVec2@1@@Z")
   Animal_ctor::proc(this:^Animal,name:cstring,pos:Vec2)->^Animal ---
   @(link_name="??0IFeedable@zoo@@QEAA@$$QEAU01@@Z")
   IFeedable_mctor::proc(this,other:^IFeedable)->^IFeedable ---
   @(link_name="??0IFeedable@zoo@@QEAA@AEBU01@@Z")
   IFeedable_cctor::proc(this,other:^IFeedable)->^IFeedable ---
   @(link_name="??0IFeedable@zoo@@QEAA@XZ")
   IFeedable_ctor::proc(this:^IFeedable)->^IFeedable ---
   @(link_name="??0INamed@zoo@@QEAA@AEBU01@@Z")
   INamed_cctor::proc(this,other:^INamed)->^INamed ---
   @(link_name="??0INamed@zoo@@QEAA@XZ")
   INamed_ctor::proc(this:^INamed)->^INamed ---
   @(link_name="??0IZooListener@zoo@@QEAA@$$QEAU01@@Z")
   IZooListener_mctor::proc(this,other:^IZooListener)->^IZooListener ---
   @(link_name="??0IZooListener@zoo@@QEAA@AEBU01@@Z")
   IZooListener_cctor::proc(this,other:^IZooListener)->^IZooListener ---
   @(link_name="??0IZooListener@zoo@@QEAA@XZ")
   IZooListener_ctor::proc(this:^IZooListener)->^IZooListener ---
   @(link_name="??0Lion@zoo@@QEAA@$$QEAV01@@Z")
   Lion_mctor::proc(this,other:^Lion)->^Lion ---
   @(link_name="??0Lion@zoo@@QEAA@AEBV01@@Z")
   Lion_cctor::proc(this,other:^Lion)->^Lion ---
   @(link_name="??0Lion@zoo@@QEAA@PEBDUVec2@1@H@Z")
   Lion_ctor::proc(this:^Lion,name:cstring,pos:Vec2,roar_db:i32)->^Lion ---
   @(link_name="??0Penguin@zoo@@QEAA@$$QEAV01@@Z")
   Penguin_mctor::proc(this,other:^Penguin)->^Penguin ---
   @(link_name="??0Penguin@zoo@@QEAA@AEBV01@@Z")
   Penguin_cctor::proc(this,other:^Penguin)->^Penguin ---
   @(link_name="??0Penguin@zoo@@QEAA@PEBDUVec2@1@@Z")
   Penguin_ctor::proc(this:^Penguin,name:cstring,pos:Vec2)->^Penguin ---
   @(link_name="??0Zoo@zoo@@QEAA@XZ")
   Zoo_ctor::proc(this:^Zoo)->^Zoo ---
   @(link_name="??1Animal@zoo@@UEAA@XZ")
   _virtual_Animal_dtor::proc(this:^Animal) ---
   @(link_name="??1INamed@zoo@@UEAA@XZ")
   INamed_dtor::proc(this:^INamed) ---
   @(link_name="??1Lion@zoo@@UEAA@XZ")
   _virtual_Lion_dtor::proc(this:^Lion) ---
   @(link_name="??1Penguin@zoo@@UEAA@XZ")
   _virtual_Penguin_dtor::proc(this:^Penguin) ---
   @(link_name="??1Zoo@zoo@@QEAA@XZ")
   Zoo_dtor::proc(this:^Zoo) ---
   @(link_name="??4Animal@zoo@@QEAAAEAV01@AEBV01@@Z")
   Animal_caop::proc(this,other:^Animal)->^Animal ---
   @(link_name="??4IFeedable@zoo@@QEAAAEAU01@$$QEAU01@@Z")
   IFeedable_maop::proc(this,other:^IFeedable)->^IFeedable ---
   @(link_name="??4IFeedable@zoo@@QEAAAEAU01@AEBU01@@Z")
   IFeedable_caop::proc(this,other:^IFeedable)->^IFeedable ---
   @(link_name="??4INamed@zoo@@QEAAAEAU01@AEBU01@@Z")
   INamed_caop::proc(this,other:^INamed)->^INamed ---
   @(link_name="??4IZooListener@zoo@@QEAAAEAU01@$$QEAU01@@Z")
   IZooListener_maop::proc(this,other:^IZooListener)->^IZooListener ---
   @(link_name="??4IZooListener@zoo@@QEAAAEAU01@AEBU01@@Z")
   IZooListener_caop::proc(this,other:^IZooListener)->^IZooListener ---
   @(link_name="??4Lion@zoo@@QEAAAEAV01@$$QEAV01@@Z")
   Lion_maop::proc(this,other:^Lion)->^Lion ---
   @(link_name="??4Lion@zoo@@QEAAAEAV01@AEBV01@@Z")
   Lion_caop::proc(this,other:^Lion)->^Lion ---
   @(link_name="??4Penguin@zoo@@QEAAAEAV01@$$QEAV01@@Z")
   Penguin_maop::proc(this,other:^Penguin)->^Penguin ---
   @(link_name="??4Penguin@zoo@@QEAAAEAV01@AEBV01@@Z")
   Penguin_caop::proc(this,other:^Penguin)->^Penguin ---
   @(link_name="??4Zoo@zoo@@QEAAAEAV01@AEBV01@@Z")
   Zoo_caop::proc(this,other:^Zoo)->^Zoo ---
   @(link_name="?add@Zoo@zoo@@QEAAXPEAVAnimal@2@@Z")
   Zoo_add::proc(this:^Zoo,a:^Animal) ---
   @(link_name="?alive_count@Animal@zoo@@SAHXZ")
   Animal_alive_count::proc()->i32 ---
   @(link_name="?centroid@Zoo@zoo@@QEBA?AUVec2@2@XZ")
   Zoo_centroid::proc(this:^Zoo,sret:^Vec2)->^Vec2 ---
   @(link_name="?count@Zoo@zoo@@QEBAHXZ")
   Zoo_count::proc(this:^Zoo)->i32 ---
   @(link_name="?distance@zoo@@YAMAEBUVec2@1@0@Z")
   distance__Vec2__Vec2::proc(#by_ptr a:Vec2,#by_ptr b:Vec2)->f32 ---
   @(link_name="?distance@zoo@@YAMAEBVAnimal@1@0@Z")
   distance__Animal__Animal::proc(#by_ptr a:Animal,#by_ptr b:Animal)->f32 ---
   @(link_name="?feed@Animal@zoo@@UEAAXH@Z")
   _virtual_Animal_feed::proc(this:^Animal,calories:i32) ---
   @(link_name="?feed_all@Zoo@zoo@@QEAAXH@Z")
   Zoo_feed_all::proc(this:^Zoo,calories:i32) ---
   @(link_name="?get@Zoo@zoo@@QEBAPEAVAnimal@2@H@Z")
   Zoo_get::proc(this:^Zoo,index:i32)->^Animal ---
   @(link_name="?hunger@Animal@zoo@@UEBAHXZ")
   _virtual_Animal_hunger::proc(this:^Animal)->i32 ---
   @(link_name="?make_animal@zoo@@YAPEAVAnimal@1@PEBD0@Z")
   make_animal::proc(kind:cstring,name:cstring)->^Animal ---
   @(link_name="?mood@Animal@zoo@@UEBA?AW4Mood@2@XZ")
   _virtual_Animal_mood::proc(this:^Animal)->Mood ---
   @(link_name="?mood@Lion@zoo@@UEBA?AW4Mood@2@XZ")
   _virtual_Lion_mood::proc(this:^Lion)->Mood ---
   @(link_name="?mood@Penguin@zoo@@UEBA?AW4Mood@2@XZ")
   _virtual_Penguin_mood::proc(this:^Penguin)->Mood ---
   @(link_name="?move@Animal@zoo@@QEAAXMM@Z")
   Animal_move_f32_f32::proc(this:^Animal,dx:f32,dy:f32) ---
   @(link_name="?move@Animal@zoo@@QEAAXUVec2@2@@Z")
   Animal_move_Vec2::proc(this:^Animal,delta:Vec2) ---
   @(link_name="?name@Animal@zoo@@UEBAPEBDXZ")
   _virtual_Animal_name::proc(this:^Animal)->cstring ---
   @(link_name="?position@Animal@zoo@@UEBA?AUVec2@2@XZ")
   _virtual_Animal_position::proc(this:^Animal,sret:^Vec2)->^Vec2 ---
   @(link_name="?roar_db@Lion@zoo@@QEBAHXZ")
   Lion_roar_db::proc(this:^Lion)->i32 ---
   @(link_name="?s_alive@Animal@zoo@@1HA")
   _protected_Animal_s_alive:i32
   @(link_name="__imp_?s_alive@Animal@zoo@@1HA")
   _protected_Animal_s_alive_ptr:^i32
   @(link_name="?set_listener@Zoo@zoo@@QEAAXPEAUIZooListener@2@@Z")
   Zoo_set_listener::proc(this:^Zoo,l:^IZooListener) ---
   @(link_name="?simulate@Zoo@zoo@@QEAAXMH@Z")
   Zoo_simulate::proc(this:^Zoo,dt:f32,steps:i32) ---
   @(link_name="?slide@Penguin@zoo@@QEAAXUVec2@2@M@Z")
   _Penguin_slide::proc(this:^Penguin,dir:Vec2,strength:f32) ---
   @(link_name="?tick@Animal@zoo@@UEAAXM@Z")
   _virtual_Animal_tick::proc(this:^Animal,dt:f32) ---
   @(link_name="?tick@Lion@zoo@@UEAAXM@Z")
   _virtual_Lion_tick::proc(this:^Lion,dt:f32) ---
   @(link_name="?tick@Penguin@zoo@@UEAAXM@Z")
   _virtual_Penguin_tick::proc(this:^Penguin,dt:f32) ---
}

distance::proc{
   distance__Vec2__Vec2,
   distance__Animal__Animal
}

Animal_move::proc{
   Animal_move_f32_f32,
   Animal_move_Vec2
}

Penguin_slide::proc(this:^Penguin,dir:Vec2,strength:f32=1.0){
   _Penguin_slide(this,dir,strength)
}
