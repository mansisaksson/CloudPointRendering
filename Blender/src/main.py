import bpy
import sys
import os
import numpy as np
import json
from mathutils import Vector
from typing import List, Set, Dict, Tuple, Optional

# change import path to path of blend-file
dir = os.path.dirname(bpy.data.filepath)
if not dir in sys.path:
    sys.path.append(dir)

import src.boundingBox as boundingBox


def vector3_to_str(vector: Tuple[float, float, float]):
    return "(" + str(vector[0]) + "," + str(vector[1]) + "," + str(vector[2]) + ")"


def generate_voxel_data(mesh: bpy.types.Object) -> Tuple[float, Vector, List[int]]:
    voxel_size = 0.5
    box = boundingBox.create_box(mesh.bound_box)

    grid_dimensions = (int(box.size.x / voxel_size),
                       int(box.size.y / voxel_size),
                       int(box.size.z / voxel_size))

    print("grid_dimensions" + vector3_to_str(box.size.to_tuple()))
    voxel_array = np.zeros(
        (grid_dimensions[0], grid_dimensions[1], grid_dimensions[2]),
        dtype=[
            ('location', [
                ('x', 'int32'),
                ('y', 'int32'),
                ('z', 'int32')
            ]),
            ('normal', [
                ('x', 'uint8'),
                ('y', 'uint8'),
                ('z', 'uint8')
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
                voxel_location = Vector((
                    (voxel_size * xc) + box.min.x,
                    (voxel_size * yc) + box.min.y,
                    (voxel_size * zc) - box.min.z)
                )
                result = mesh.closest_point_on_mesh(voxel_location, voxel_size)  # type: Tuple[bool, Vector, Vector, int]

                voxel_array[xc, yc, zc]['location'] = (voxel_location.x, voxel_location.y, voxel_location.z)
                if result[0]:
                    voxel_array[xc, yc, zc]['normal'] = (result[1].x * 255, result[1].y * 255, result[1].z * 255)
                voxel_array[xc, yc, zc]['color'] = (255, 255, 255)  # No point in adding color atm, better to focus on render algorithm

    return voxel_size, box.size, voxel_array


def main():
    for obj in bpy.context.selected_objects:
        print("Found Selected Object: " + obj.name)
        if obj.type == 'MESH':
            voxel_data = generate_voxel_data(obj)
            print(voxel_data)

            path = dir + "\\export\\"
            os.makedirs(path, exist_ok=True)
            with open(path + "export_data.txt", "w") as file:
                file.write(str(voxel_data))

            # img = bpy.data.images[0]  # type: bpy.types.Image
            # for pixel in img.pixels:
            #     print(pixel)

main()
