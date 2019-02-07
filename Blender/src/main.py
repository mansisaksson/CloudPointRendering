import bpy
from bpy import context

def main():
    obj = context.selected_objects
    vertices = obj.data.vertices
    
    print(vertices[0])

main()
