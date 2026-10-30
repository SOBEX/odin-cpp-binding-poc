package main

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"

demangle_exports::proc(){
   _exports,exports_err:=os.read_entire_file_from_path("../exports.txt",context.allocator)
   assert(exports_err==nil)
   defer delete(_exports)
   exports:=string(_exports)
   _export_lines:=strings.split_lines(exports)
   defer delete(_export_lines)
   export_lines_start,_:=slice.linear_search(_export_lines,"    ordinal hint RVA      name")
   export_lines_end,_:=slice.linear_search(_export_lines,"  Summary")
   export_lines:=_export_lines[export_lines_start+2:export_lines_end-1]

   _symbols,symbols_err:=os.read_entire_file_from_path("../symbols.txt",context.allocator)
   assert(symbols_err==nil)
   defer delete(_symbols)
   symbols:=string(_symbols)
   symbol_lines:=strings.split_lines(symbols)
   defer delete(symbol_lines)

   for export_line in export_lines{
      export_fields:=strings.fields(export_line)
      assert(len(export_fields)==4)
      defer delete(export_fields)
      for symbol_line in symbol_lines{
         if strings.contains(symbol_line,export_fields[3]){
            start:=strings.index(symbol_line,"| ")
            assert(start!=-1)
            parts:=strings.split_n(symbol_line[start+2:]," ",2)
            assert(len(parts)==2)
            parts[1]=parts[1][1:len(parts[1])-1]
            //parts[1]=strings.trim_prefix(parts[1],"public: ")
            //parts[1]=strings.trim_prefix(parts[1],"protected: ")
            //TODO filter out vtables or more generally everything that isnt `notype ()` but also somehow keep actual globals
            fmt.println(parts)
            break
         }
      }
   }
}

main::proc(){
   demangle_exports()

   harness()

   print_alive_count::proc(){
      fmt.println(Animal_alive_count(),_protected_Animal_s_alive)
   }

   print_alive_count()
   l:=make_animal("lion","Lion")
   print_alive_count()
   l->dtor()
   print_alive_count()

   fmt.println(_new,_delete,_delete_vector)
   a:=_new(24)
   fmt.println(a)
   _delete(a,24)
}
