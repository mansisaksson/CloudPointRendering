import bpy
import sys
import os
import numpy as np
from typing import List, Set, Dict, Tuple, Optional

# change import path to path of blend-file
dir = os.path.dirname(bpy.data.filepath)
if not dir in sys.path:
    sys.path.append(dir)

import src.boundingBox as boundingBox


def vector3_to_str(vector: Tuple[float, float, float]):
    return "(" + str(vector[0]) + "," + str(vector[1]) + "," + str(vector[2]) + ")"


def generate_voxel_data(mesh: bpy.types.Mesh):
    voxel_size = 0.5
    box = boundingBox.create_box(mesh.bound_box)

    grid_dimensions = (int(box.size[0] / voxel_size),
                       int(box.size[1] / voxel_size),
                       int(box.size[2] / voxel_size))

    print("grid_dimensions" + vector3_to_str(box.size))
    voxel_array = np.zeros(
        (grid_dimensions[0], grid_dimensions[1], grid_dimensions[2]),
        dtype=[
            ('location', [
                ('x', 'float'),
                ('y', 'float'),
                ('z', 'float')
            ]),
            ('normal', [
                ('x', 'float'),
                ('y', 'float'),
                ('z', 'float')
            ]),
            ('color', [
                ('r', 'uint8'),
                ('g', 'uint8'),
                ('b', 'uint8')
            ])
        ])

    for zc in range(0, grid_dimensions[2]):
        for yc in range(0, grid_dimensions[1]):
            for xc in range(0, grid_dimensions[0]):
                voxel_array[xc, yc, zc]['location'] = ((voxel_size * xc) + box.min[0], (voxel_size * yc) + box.min[1], (voxel_size * zc) - box.min[2])


    print(voxel_array)

    return

    polygons = mesh.data.polygons  # type: bpy.types.Mesh.polygons
    for face in polygons:
        vertices = face.vertices  # type: List[bpy.types.MeshVertex]

        for vert in vertices:
            local_point = mesh.data.vertices[vert].co
            world_point = mesh.matrix_world * local_point
            #print("vert", vert, " vert co", world_point)


def main():
    for obj in bpy.context.selected_objects:
        print("Found Selected Object: " + obj.name)
        if obj.type == 'MESH':
            generate_voxel_data(obj)

    # obj = bpy.context.selected_objects[0]  # type: bpy.types.Object
    # obj = bpy.data.objects[1]  # type: bpy.types.Object


main()
