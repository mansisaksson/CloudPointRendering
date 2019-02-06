import bpy
from bpy import context


def main():
    obj = context.active_object
    vertices = obj.data.vertices

    print(vertices[0])

main()
