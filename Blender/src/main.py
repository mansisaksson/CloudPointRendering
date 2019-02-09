import bpy
import sys
import os
import numpy as np
from mathutils import Vector
from typing import List, Tuple

# change import path to path of blend-file
dir = os.path.dirname(bpy.data.filepath)
if dir not in sys.path:
    sys.path.append(dir)

import src.boundingBox as boundingBox


def generate_voxel_data(mesh: bpy.types.Object):
    voxel_size = 0.05
    box = boundingBox.create_box(mesh.bound_box)

    grid_dimensions = (int(box.size.x / voxel_size),
                       int(box.size.y / voxel_size),
                       int(box.size.z / voxel_size))

    print("grid_dimensions: " + str(grid_dimensions))
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

                # TODO: No need to save location, although it's convenient for debugging
                voxel_array[xc, yc, zc]['location'] = (voxel_location.x, voxel_location.y, voxel_location.z)
                if result[0]:
                    voxel_array[xc, yc, zc]['normal'] = (result[1].x * 255, result[1].y * 255, result[1].z * 255)
                    voxel_array[xc, yc, zc]['color'] = (255, 255, 255)  # No point in adding color atm, better to focus on render algorithm
                else:
                    voxel_array[xc, yc, zc]['normal'] = (0.0, 0.0, 0.0)
                    voxel_array[xc, yc, zc]['color'] = (0, 0, 0)

    return grid_dimensions, voxel_array


def generate_search_tree(voxel_data):
    dimensions = voxel_data[0]
    voxel_array = voxel_data[1]
    layers = []

    bottom_layer = np.zeros(
        (dimensions[0], dimensions[1], dimensions[2]),
        dtype=[
            ('normal', [
                ('x', 'uint8'),
                ('y', 'uint8'),
                ('z', 'uint8')
            ]),
            ('color', [
                ('r', 'uint8'),
                ('g', 'uint8'),
                ('b', 'uint8')
            ]),
            ('child_0', 'uint32'),
            ('child_1', 'uint32'),
            ('child_2', 'uint32'),
            ('child_3', 'uint32'),
            ('child_4', 'uint32'),
            ('child_5', 'uint32'),
            ('child_6', 'uint32'),
            ('child_7', 'uint32')
        ])
    for x in range(0, dimensions[0]):
        for y in range(0, dimensions[1]):
            for z in range(0, dimensions[2]):
                bottom_layer[x, y, z]['color'] = voxel_array[x, y, z]['color']
                bottom_layer[x, y, z]['normal'] = voxel_array[x, y, z]['normal']
                # children will automatically be filled as 0

    generate_node_layers_recursive(layers, bottom_layer)


def generate_node_layers_recursive(layers: List, previous_layer):
    layer = generate_new_layer(previous_layer)
    print(layer.shape)
    if layer.shape[0] > 4 and layer.shape[1] > 4 and layer.shape[2] > 4:
        layers.append(layer)
        generate_node_layers_recursive(layers, layer)


def generate_new_layer(previous_layer):
    child_base = 2
    children_per_node = child_base ** 3  # 8 or the number of children per node

    dimensions = [int(previous_layer.shape[0] / children_per_node),
                  int(previous_layer.shape[1] / children_per_node),
                  int(previous_layer.shape[2] / children_per_node)]

    node_structure = np.dtype([
        ('normal', [
            ('x', 'uint8'),
            ('y', 'uint8'),
            ('z', 'uint8')
        ]),
        ('color', [
            ('r', 'uint8'),
            ('g', 'uint8'),
            ('b', 'uint8')
        ]),
        ('child_0', 'uint32'),
        ('child_1', 'uint32'),
        ('child_2', 'uint32'),
        ('child_3', 'uint32'),
        ('child_4', 'uint32'),
        ('child_5', 'uint32'),
        ('child_6', 'uint32'),
        ('child_7', 'uint32')
    ])

    new_layer = np.zeros((dimensions[0], dimensions[1], dimensions[2]), node_structure)

    for x in range(0, dimensions[0], child_base):
        for y in range(0, dimensions[1], child_base):
            for z in range(0, dimensions[2], child_base):
                child_nodes = [
                    previous_layer[x + 0, y + 0, z + 0],
                    previous_layer[x + 0, y + 1, z + 0],
                    previous_layer[x + 1, y + 0, z + 0],
                    previous_layer[x + 1, y + 1, z + 0],

                    previous_layer[x + 0, y + 0, z + 1],
                    previous_layer[x + 0, y + 1, z + 1],
                    previous_layer[x + 1, y + 0, z + 1],
                    previous_layer[x + 1, y + 1, z + 1]
                ]

                xc = x / children_per_node
                yc = y / children_per_node
                zc = z / children_per_node

                # previous_layer.__array_interface__['data'] returns (pointer, read_only_flag)
                array_memory_addr = previous_layer.__array_interface__['data'][0]
                for i, child_node in enumerate(child_nodes):
                    child = child_nodes[i]
                    child_memory_addr = child.__array_interface__['data'][0]

                    # store the memory offset needed to find the child in the array
                    new_layer[xc, yc, zc]['child_' + str(i)] = (child_memory_addr - array_memory_addr)

            new_layer[xc, yc, zc]['color'] = (0, 0, 0)  # TODO: get avg color from children
            new_layer[xc, yc, zc]['normal'] = (0.0, 0.0, 0.0)  # TODO: get avg normal from children

    return new_layer


def main():
    for obj in bpy.context.selected_objects:
        print("Found Selected Object: " + obj.name)
        if obj.type == 'MESH':
            voxel_data = generate_voxel_data(obj)
            # print(voxel_data)

            layers = generate_search_tree(voxel_data)
            print (layers)
            return

            path = dir + "\\export\\"
            os.makedirs(path, exist_ok=True)
            with open(path + "export_data.txt", "w") as file:
                file.write(str(voxel_data))

            # img = bpy.data.images[0]  # type: bpy.types.Image
            # for pixel in img.pixels:
            #     print(pixel)

main()
