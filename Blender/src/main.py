import bpy

def main():
    obj = bpy.context.selected_objects
    vertices = obj.data.vertices

    print(vertices[0])

main()
