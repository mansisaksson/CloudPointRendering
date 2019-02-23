from mathutils import Vector
from typing import List, Set, Dict, Tuple, Optional


class BoundingBox:
    def __init__(self):
        self.origin = (0.0, 0.0, 0.0)  # type: Vector
        self.extent = (0.0, 0.0, 0.0)  # type: Vector

    def __init__(self, origin: Vector, extent: Vector):
        self.origin = origin  # type: Vector
        self.extent = extent  # type: Vector


def create_box(locations: List[Tuple[float, float, float]]) -> BoundingBox:
    loc_min = Vector((0, 0, 0))
    loc_max = Vector((0, 0, 0))
    aggr_origin = Vector((0, 0, 0))
    for loc in locations:
        aggr_origin += Vector(loc)
        if loc[0] < loc_min.x or loc[1] < loc_min.y or loc[2] < loc_min.z:
            loc_min = Vector(loc)
        elif loc[0] > loc_max.x or loc[1] > loc_max.y or loc[2] > loc_max.z:
            loc_max = Vector(loc)

    extent = Vector((loc_max.x - loc_min.x, loc_max.y - loc_min.y, loc_max.z - loc_min.z))
    extent = Vector((abs(extent.x / 2.0), abs(extent.y / 2.0), abs(extent.z / 2.0)))
    origin = Vector((aggr_origin.x / 4.0, aggr_origin.y / 4.0, aggr_origin.z / 4.0))

    return BoundingBox(origin, extent)

