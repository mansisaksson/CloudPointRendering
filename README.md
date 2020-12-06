# Point Cloud Rendering, using Unity Shaders

Created as an experiment to try and render point data by storing the points in a sorted octree texture, and then run a point-finding algorithm on the GPU.

Abandoned since it became apparent that the point-finding algorithm was not suited for the GPU, and created too many branching paths.

The end result did however end up looking pretty cool.
![Final Result](https://nextcloud.mansisaksson.com:1443/index.php/s/ya8PQFYeLn6RQtz/preview)
