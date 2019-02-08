from mathutils import Vector
from typing import List, Set, Dict, Tuple, Optional


class BoundingBox:
    def __init__(self):
        self.min = (0.0, 0.0, 0.0)  # type: Vector
        self.max = (0.0, 0.0, 0.0)  # type: Vector
        self.size = (0.0, 0.0, 0.0)  # type: Vector

    def __init__(self, min: Vector, max: Vector, size: Vector):
        self.min = min  # type: Vector
        self.max = max  # type: Vector
        self.size = size  # type: Vector


def create_box(location: List[Tuple[float, float, float]]) -> BoundingBox:
    loc_min = Vector((0, 0, 0))
    loc_max = Vector((0, 0, 0))
    for loc in location:
        # print(loc[2])
        if loc[0] < loc_min[0] or loc[1] < loc_min[1] or loc[2] > loc_min[2]:
            loc_min = Vector(loc)
        elif loc[0] > loc_min[0] or loc[1] > loc_min[1] or loc[2] < loc_min[2]:
            loc_max = loc

    size = Vector((loc_max[0] - loc_min[0], loc_max[1] - loc_min[1], loc_min[2] - loc_max[2]))
    box = BoundingBox(loc_min, loc_max, size)
    return box

