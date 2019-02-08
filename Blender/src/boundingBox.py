from typing import List, Set, Dict, Tuple, Optional


class BoundingBox:
    def __init__(self):
        self.min = (0.0, 0.0, 0.0)  # type: Tuple[float, float, float]
        self.max = (0.0, 0.0, 0.0)  # type: Tuple[float, float, float]
        self.size = (0.0, 0.0, 0.0)  # type: Tuple[float, float, float]

    def __init__(self, min, max, size):
        self.min = min  # type: Tuple[float, float, float]
        self.max = max  # type: Tuple[float, float, float]
        self.size = size  # type: Tuple[float, float, float]


def create_box(location: List[Tuple[float, float, float]]) -> BoundingBox:
    loc_min = (0, 0, 0)
    loc_max = (0, 0, 0)
    for loc in location:
        # print(loc[2])
        if loc[0] < loc_min[0] or loc[1] < loc_min[1] or loc[2] > loc_min[2]:
            loc_min = loc
        elif loc[0] > loc_min[0] or loc[1] > loc_min[1] or loc[2] < loc_min[2]:
            loc_max = loc

    size = (loc_max[0] - loc_min[0], loc_max[1] - loc_min[1], loc_min[2] - loc_max[2])
    box = BoundingBox(loc_min, loc_max, size)
    return box

