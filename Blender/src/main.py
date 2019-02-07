import bpy


def main():
    for item in bpy.context.selected_objects:
        print(item.name)
        if item.type == 'MESH':
            for vertex in item.data.vertices:
                print(vertex.co)

    #obj = bpy.context.selected_objects[0]  # type: bpy.types.Object
    #obj = bpy.data.objects[1]  # type: bpy.types.Object

    current_obj = bpy.context.active_object

    print("=" * 40)  # printing marker
    for face in current_obj.data.polygons:
        verts_in_face = face.vertices[:]
        print("face index", face.index)
        print("normal", face.normal)
        for vert in verts_in_face:
            local_point = current_obj.data.vertices[vert].co
            world_point = current_obj.matrix_world * local_point
            print("vert", vert, " vert co", world_point)


main()
