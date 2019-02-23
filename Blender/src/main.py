import bpy
import sys
import os
import numpy as np
from mathutils import Vector
from typing import List, Tuple
from math import ceil, log

# change import path to path of blend-file
dir = os.path.dirname(bpy.data.filepath)
if dir not in sys.path:
    sys.path.append(dir)

import src.boundingBox as boundingBox


def generate_search_tree(mesh: bpy.types.Object):
    """node_structure = np.dtype([
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
    ])"""
    
    node_structure = np.dtype([
        ('normal', [
            ('x', 'float'),
            ('y', 'float'),
            ('z', 'float')
        ]),
        ('color', [
            ('r', 'float'),
            ('g', 'float'),
            ('b', 'float'),
            ('a', 'float')
        ])
    ])

    children_per_node = 8  # needs to be ^3 TODO: need to make sure the voxel size fits with the child count
    nr_of_voxel_layers = 6

    def generate_bottom_layer():
        box = boundingBox.create_box(mesh.bound_box)
        print("Box Bounds: " + str(box.origin) + ", " + str(box.extent))
        nr_of_voxels = children_per_node ** nr_of_voxel_layers
        nr_of_voxels_per_side = round(nr_of_voxels ** (1. / 3))
        voxel_size = ((box.extent.x * 2) / nr_of_voxels_per_side)  # TODO: using x component as I assume this is a cube

        grid_dimensions = (nr_of_voxels_per_side,
                           nr_of_voxels_per_side,
                           nr_of_voxels_per_side)

        print("Generating bottom layer with dimensions: " + str(grid_dimensions))
        voxel_array = np.zeros((grid_dimensions[0], grid_dimensions[1], grid_dimensions[2]), node_structure)
        for zc in range(0, grid_dimensions[2]):
            for yc in range(0, grid_dimensions[1]):
                for xc in range(0, grid_dimensions[0]):
                    voxel_location = Vector((
                        (voxel_size * xc) - box.extent.x,
                        (voxel_size * yc) - box.extent.y,
                        (voxel_size * zc) - box.extent.z
                    ))
                    result = mesh.closest_point_on_mesh(voxel_location,
                                                        voxel_size)  # type: Tuple[bool, Vector, Vector, int]
                    if result[0]:
                        voxel_array[xc, yc, zc]['normal'] = (result[1].x, result[1].y, result[1].z)
                        voxel_array[xc, yc, zc]['color'] = (1.0, 1.0, 1.0, 1.0)  # No point in adding color atm, better to focus on render algorithm
                    else:
                        voxel_array[xc, yc, zc]['normal'] = (0.0, 0.0, 0.0)
                        voxel_array[xc, yc, zc]['color'] = (0.0, 0.0, 0.0, 0.0)

                    # No need to save child data, as bottom layer has no children

        return voxel_array

    def generate_node_layers_recursive(layers, previous_layer):
        child_per_side = round(children_per_node ** (1. / 3))
        dimensions = [int(previous_layer.shape[0] / child_per_side),
                      int(previous_layer.shape[1] / child_per_side),
                      int(previous_layer.shape[2] / child_per_side)]
        print("Generate new layer with dimensions: " + str(dimensions))
        new_layer = np.zeros((dimensions[0], dimensions[1], dimensions[2]), node_structure)

        for z in range(0, dimensions[2]):
            for y in range(0, dimensions[1]):
                for x in range(0, dimensions[0]):
                    xc = x * child_per_side
                    yc = y * child_per_side
                    zc = z * child_per_side

                    child_nodes = [
                        previous_layer[xc + 0, yc + 0, zc + 0],
                        previous_layer[xc + 0, yc + 1, zc + 0],
                        previous_layer[xc + 1, yc + 0, zc + 0],
                        previous_layer[xc + 1, yc + 1, zc + 0],

                        previous_layer[xc + 0, yc + 0, zc + 1],
                        previous_layer[xc + 0, yc + 1, zc + 1],
                        previous_layer[xc + 1, yc + 0, zc + 1],
                        previous_layer[xc + 1, yc + 1, zc + 1]
                    ]

                    color_sum = [0, 0, 0, 0]
                    normal_sum = [0, 0, 0]

                    # previous_layer.__array_interface__['data'] returns (pointer, read_only_flag)
                    # array_memory_addr = previous_layer.__array_interface__['data'][0]
                    for i, child_node in enumerate(child_nodes):
                        child = child_nodes[i]

                        color_sum[0] += child['color']['r']
                        color_sum[1] += child['color']['g']
                        color_sum[2] += child['color']['b']
                        color_sum[3] += child['color']['a']

                        normal_sum[0] += child['normal']['x']
                        normal_sum[1] += child['normal']['y']
                        normal_sum[2] += child['normal']['z']

                        """# store the memory offset needed to find the child in the array
                        child_memory_addr = child.__array_interface__['data'][0]
                        new_layer[x, y, z]['child_' + str(i)] = (child_memory_addr - array_memory_addr)"""

                    new_layer[x, y, z]['color'] = (color_sum[0] / len(child_nodes),
                                                   color_sum[1] / len(child_nodes),
                                                   color_sum[2] / len(child_nodes),
                                                   color_sum[3] / len(child_nodes))
                    new_layer[x, y, z]['normal'] = (normal_sum[0] / len(child_nodes),
                                                    normal_sum[1] / len(child_nodes),
                                                    normal_sum[2] / len(child_nodes))

        layers.append(new_layer)
        if new_layer.shape[0] > 1 and new_layer.shape[1] > 1 and new_layer.shape[2] > 1:
            generate_node_layers_recursive(layers, new_layer)

    bottom_layer = generate_bottom_layer()
    layers = [bottom_layer]
    generate_node_layers_recursive(layers, bottom_layer)
    return layers


def main():
    for obj in bpy.context.selected_objects:
        print("Found Selected Object: " + obj.name)
        if obj.type == 'MESH':
            layers = generate_search_tree(obj)

            for i, layer in enumerate(layers):
                """path = dir + "\\export\\"
                os.makedirs(path, exist_ok=True)
                with open(path + "layer" + str(i) + ".txt", "wb") as file:
                    file.write(layer)"""

                data_block_size = layer.shape[0] * layer.shape[1] * layer.shape[2]
                size = ceil(data_block_size ** (1 / 2.)), ceil(data_block_size ** (1 / 2.))
                print("Saving data_block_size " + str(data_block_size) + " with image dimensions" + str(size))
                image = bpy.data.images.new("MyImage", alpha=True, width=size[0], height=size[1])  # type: bpy.types.Image

                pixel_pos = 0
                pixels = [None] * size[0] * size[1]
                for z in range(0, layer.shape[2]):
                    for y in range(0, layer.shape[1]):
                        for x in range(0, layer.shape[0]):
                            r = layer[x, y, z]['color']['r']
                            g = layer[x, y, z]['color']['g']
                            b = layer[x, y, z]['color']['b']
                            a = layer[x, y, z]['color']['a']

                            pixels[pixel_pos] = [r, g, b, a]
                            pixel_pos += 1

                # We might not fill out the entire texture array, fill rest with empty color
                for p in range(pixel_pos, size[0] * size[1]):
                    pixels[p] = [0.0, 0.0, 0.0, 0.0]

                # flatten list
                pixels = [chan for px in pixels for chan in px]

                # assign pixels
                image.pixels = pixels

                # write image
                image.filepath_raw = dir + "\\export\\" "layer" + str(len(layers) - i - 1) + ".png"
                image.file_format = 'PNG'
                image.save()

main()
