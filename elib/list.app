module elib/list

//   function isFirst(xs: List<Entity>, x: Entity): Bool {
//     return xs.indexOf(x) > 0;
//   }
//   
//   function isLast(xs: List<Entity>, x: Entity): Bool {
//     return xs.indexOf(x) == xs.length - 1;
//   }
// 
//   function up(xs: List<Entity>, x: Entity) {
//     var i := xs.indexOf(x);
//     if(xs != null && i > 0) {
//       xs.set(i, xs.get(i - 1));
//       xs.set(i - 1, x);
//     }
//   }
//   
//   function down(xs: List<Entity>, x: Entity) {
//     var i := xs.indexOf(x);
//     if(xs != null && i < xs.length - 1) {
//       xs.set(i, xs.get(i + 1));
//       xs.set(i + 1, x);
//     }
//   }