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


def generate_search_tree(mesh: bpy.types.Object):
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

    children_per_node = 2 ** 3  # needs to be ^3 TODO: need to make sure the voxel size fits with the child count
    voxel_size = 0.05

    def generate_bottom_layer():
        box = boundingBox.create_box(mesh.bound_box)

        # TODO: the dimentions needs to be x^4
        grid_dimensions = (int(box.size.x / voxel_size),
                           int(box.size.y / voxel_size),
                           int(box.size.z / voxel_size))

        print("Generating bottom layer with dimensions: " + str(grid_dimensions))
        voxel_array = np.zeros((grid_dimensions[0], grid_dimensions[1], grid_dimensions[2]), node_structure)
        for zc in range(0, grid_dimensions[2]):
            for yc in range(0, grid_dimensions[1]):
                for xc in range(0, grid_dimensions[0]):
                    voxel_location = Vector((
                        (voxel_size * xc) + box.min.x,
                        (voxel_size * yc) + box.min.y,
                        (voxel_size * zc) - box.min.z)
                    )
                    result = mesh.closest_point_on_mesh(voxel_location,
                                                        voxel_size)  # type: Tuple[bool, Vector, Vector, int]

                    if result[0]:
                        voxel_array[xc, yc, zc]['normal'] = (result[1].x * 255, result[1].y * 255, result[1].z * 255)
                        voxel_array[xc, yc, zc]['color'] = (255, 255, 255)  # No point in adding color atm, better to focus on render algorithm
                    else:
                        voxel_array[xc, yc, zc]['normal'] = (0, 0, 0)
                        voxel_array[xc, yc, zc]['color'] = (0, 0, 0)

                    # No need to save child data, as bottom layer has no children

        return voxel_array

    bottom_layer = generate_bottom_layer()
    layers = [bottom_layer]

    def generate_node_layers_recursive(previous_layer):
        def generate_new_layer():
            child_base = int(children_per_node ** (1. / 3))

            dimensions = [int(previous_layer.shape[0] / children_per_node),
                          int(previous_layer.shape[1] / children_per_node),
                          int(previous_layer.shape[2] / children_per_node)]

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

                        color_sum = [0, 0, 0]
                        normal_sum = [0, 0, 0]

                        # previous_layer.__array_interface__['data'] returns (pointer, read_only_flag)
                        array_memory_addr = previous_layer.__array_interface__['data'][0]
                        for i, child_node in enumerate(child_nodes):
                            child = child_nodes[i]

                            color_sum[0] += child['color']['r']
                            color_sum[1] += child['color']['g']
                            color_sum[2] += child['color']['b']

                            normal_sum[0] += child['normal']['x']
                            normal_sum[1] += child['normal']['y']
                            normal_sum[2] += child['normal']['z']

                            # store the memory offset needed to find the child in the array
                            child_memory_addr = child.__array_interface__['data'][0]
                            new_layer[xc, yc, zc]['child_' + str(i)] = (child_memory_addr - array_memory_addr)

                        new_layer[xc, yc, zc]['color'] = (color_sum[0] / len(child_nodes),
                                                          color_sum[1] / len(child_nodes),
                                                          color_sum[2] / len(child_nodes))
                        new_layer[xc, yc, zc]['normal'] = (normal_sum[0] / len(child_nodes),
                                                           normal_sum[1] / len(child_nodes),
                                                           normal_sum[2] / len(child_nodes))

            return new_layer

        layer = generate_new_layer()
        print(layer.shape)
        layers.append(layer)
        if layer.shape[0] > 1 and layer.shape[1] > 1 and layer.shape[2] > 1:
            generate_node_layers_recursive(layer)

    generate_node_layers_recursive(bottom_layer)
    return layers


def main():
    for obj in bpy.context.selected_objects:
        print("Found Selected Object: " + obj.name)
        if obj.type == 'MESH':
            layers = generate_search_tree(obj)
            # print(layers)
            return

            path = dir + "\\export\\"
            os.makedirs(path, exist_ok=True)
            with open(path + "export_data.txt", "w") as file:
                file.write(str(voxel_data))

            # img = bpy.data.images[0]  # type: bpy.types.Image
            # for pixel in img.pixels:
            #     print(pixel)

main()
