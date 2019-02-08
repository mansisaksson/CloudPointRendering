import bpy
import sys
import os
import numpy as np
from mathutils import Vector
from typing import List, Set, Dict, Tuple, Optional

# change import path to path of blend-file
dir = os.path.dirname(bpy.data.filepath)
if not dir in sys.path:
    sys.path.append(dir)

import src.boundingBox as boundingBox


def vector3_to_str(vector: Tuple[float, float, float]):
    return "(" + str(vector[0]) + "," + str(vector[1]) + "," + str(vector[2]) + ")"


def generate_voxel_data(mesh: bpy.types.Object):
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
                voxel_location = Vector((
                    (voxel_size * xc) + box.min.x,
                    (voxel_size * yc) + box.min.y,
                    (voxel_size * zc) - box.min.z)
                )
                result = mesh.closest_point_on_mesh(voxel_location, voxel_size)  # type: Tuple[bool, Vector, Vector, int]

                voxel_array[xc, yc, zc]['location'] = (voxel_location.x, voxel_location.y, voxel_location.z)
                voxel_array[xc, yc, zc]['normal'] = (result[1].x, result[1].y, result[1].z)

    print(voxel_array)
    return voxel_array


def main():
    for obj in bpy.context.selected_objects:
        print("Found Selected Object: " + obj.name)
        if obj.type == 'MESH':
            # generate_voxel_data(obj)

            # img = bpy.data.images[0]  # type: bpy.types.Image

            # for pixel in img.pixels:
            #     print(pixel)

            # for uvface in bpy.context.object.data.uv_textures.active.data:
            #    uvface.image = img
            # texture_coords.py

            obj = bpy.context.active_object
            mesh = obj.data

            is_editmode = (obj.mode == 'EDIT')
            if is_editmode:
                bpy.ops.object.mode_set(mode='OBJECT', toggle=False)

            uvtex = mesh.uv_textures.active
            print("test start/n")
            # adjust UVs
            count = 0
            for i, uv in enumerate(uvtex.data):
                print(uvtex)
                uvs = uv.uv1, uv.uv2, uv.uv3, uv.uv4

                for j, v_idx in enumerate(mesh.faces[i].vertices):
                    # Face index matches with uvtex.data index, 4 uvs belong to this face
                    # v_idx points to that specific face vertices
                    # vertex index starts from 0 and uvs also from 0, they match
                    # Vertex UV coords are found
                    print(uv)
                    print(v_idx)
                    print(j)
                    print('/n')

                #    print(uvs[0])
                #    print(uvs[1])
                #    print(uvs[2])
                #    print(uvs[3])
                #    print("/n")
                count += 1
            print("test end/n")
            print("uv coords count: " + str(count))


main()
