union(){
  polyhedron(points=[[0,0,10],[10,0,10],[0,10,10],[5,5,17.5]], triangles=[[0,1,2],[1,0,3],[0,2,3],[2,1,3]]);
  polyhedron(points=[[10,10,10],[10,0,10],[0,10,10],[5,5,17.5]], triangles=[[0,1,2], [1,0,3],[0,2,3],[2,1,3]]);
  cube(10,10,5);
}
