def brush_edit(stroke=None):
    '''Apply a stroke of brush to the particles 

    :param stroke: Stroke 
    :type stroke: bpy_prop_collection of OperatorStrokeElement, (optional)
    '''

    pass


def connect_hair(all=False):
    '''Connect hair to the emitter mesh 

    :param all: All hair, Connect all hair systems to the emitter mesh 
    :type all: boolean, (optional)
    '''

    pass


def copy_particle_systems(space='OBJECT',
                          remove_target_particles=True,
                          use_active=False):
    '''Copy particle systems from the active object to selected objects 

    :param space: Space, Space transform for copying from one object to anotherOBJECT Object, Copy inside each object’s local space.WORLD World, Copy in world space. 
    :type space: enum in ['OBJECT', 'WORLD'], (optional)
    :param remove_target_particles: Remove Target Particles, Remove particle systems on the target objects 
    :type remove_target_particles: boolean, (optional)
    :param use_active: Use Active, Use the active particle system from the context 
    :type use_active: boolean, (optional)
    '''

    pass


def delete(type='PARTICLE'):
    '''Delete selected particles or keys 

    :param type: Type, Delete a full particle or only keys 
    :type type: enum in ['PARTICLE', 'KEY'], (optional)
    '''

    pass


def disconnect_hair(all=False):
    '''Disconnect hair from the emitter mesh 

    :param all: All hair, Disconnect all hair systems from the emitter mesh 
    :type all: boolean, (optional)
    '''

    pass


def dupliob_copy():
    '''Duplicate the current dupliobject 

    '''

    pass


def dupliob_move_down():
    '''Move dupli object down in the list 

    '''

    pass


def dupliob_move_up():
    '''Move dupli object up in the list 

    '''

    pass


def dupliob_remove():
    '''Remove the selected dupliobject 

    '''

    pass


def edited_clear():
    '''Undo all edition performed on the particle system 

    '''

    pass


def hair_dynamics_preset_add(name="", remove_active=False):
    '''Add or remove a Hair Dynamics Preset 

    :param name: Name, Name of the preset, used to make the path name 
    :type name: string, (optional, never None)
    :param remove_active: remove_active 
    :type remove_active: boolean, (optional)
    '''

    pass


def hide(unselected=False):
    '''Hide selected particles 

    :param unselected: Unselected, Hide unselected rather than selected 
    :type unselected: boolean, (optional)
    '''

    pass


def mirror():
    '''Duplicate and mirror the selected particles along the local X axis 

    '''

    pass


def new():
    '''Add new particle settings 

    '''

    pass


def new_target():
    '''Add a new particle target 

    '''

    pass


def particle_edit_toggle():
    '''Toggle particle edit mode 

    '''

    pass


def rekey(keys_number=2):
    '''Change the number of keys of selected particles (root and tip keys included) 

    :param keys_number: Number of Keys 
    :type keys_number: int in [2, inf], (optional)
    '''

    pass


def remove_doubles(threshold=0.0002):
    '''Remove selected particles close enough of others 

    :param threshold: Merge Distance, Threshold distance withing which particles are removed 
    :type threshold: float in [0, inf], (optional)
    '''

    pass


def reveal():
    '''Show hidden particles 

    '''

    pass


def select_all(action='TOGGLE'):
    '''(De)select all particles’ keys 

    :param action: Action, Selection action to executeTOGGLE Toggle, Toggle selection for all elements.SELECT Select, Select all elements.DESELECT Deselect, Deselect all elements.INVERT Invert, Invert selection of all elements. 
    :type action: enum in ['TOGGLE', 'SELECT', 'DESELECT', 'INVERT'], (optional)
    '''

    pass


def select_less():
    '''Deselect boundary selected keys of each particle 

    '''

    pass


def select_linked(deselect=False, location=(0, 0)):
    '''Select nearest particle from mouse pointer 

    :param deselect: Deselect, Deselect linked keys rather than selecting them 
    :type deselect: boolean, (optional)
    :param location: Location 
    :type location: int array of 2 items in [0, inf], (optional)
    '''

    pass


def select_more():
    '''Select keys linked to boundary selected keys of each particle 

    '''

    pass


def select_random(percent=50.0, seed=0, action='SELECT', type='HAIR'):
    '''Select a randomly distributed set of hair or points 

    :param percent: Percent, Percentage of objects to select randomly 
    :type percent: float in [0, 100], (optional)
    :param seed: Random Seed, Seed for the random number generator 
    :type seed: int in [0, inf], (optional)
    :param action: Action, Selection action to executeSELECT Select, Select all elements.DESELECT Deselect, Deselect all elements. 
    :type action: enum in ['SELECT', 'DESELECT'], (optional)
    :param type: Type, Select either hair or points 
    :type type: enum in ['HAIR', 'POINTS'], (optional)
    '''

    pass


def select_roots(action='SELECT'):
    '''Select roots of all visible particles 

    :param action: Action, Selection action to executeTOGGLE Toggle, Toggle selection for all elements.SELECT Select, Select all elements.DESELECT Deselect, Deselect all elements.INVERT Invert, Invert selection of all elements. 
    :type action: enum in ['TOGGLE', 'SELECT', 'DESELECT', 'INVERT'], (optional)
    '''

    pass


def select_tips(action='SELECT'):
    '''Select tips of all visible particles 

    :param action: Action, Selection action to executeTOGGLE Toggle, Toggle selection for all elements.SELECT Select, Select all elements.DESELECT Deselect, Deselect all elements.INVERT Invert, Invert selection of all elements. 
    :type action: enum in ['TOGGLE', 'SELECT', 'DESELECT', 'INVERT'], (optional)
    '''

    pass


def shape_cut():
    '''Cut hair to conform to the set shape object 

    '''

    pass


def subdivide():
    '''Subdivide selected particles segments (adds keys) 

    '''

    pass


def target_move_down():
    '''Move particle target down in the list 

    '''

    pass


def target_move_up():
    '''Move particle target up in the list 

    '''

    pass


def target_remove():
    '''Remove the selected particle target 

    '''

    pass


def unify_length():
    '''Make selected hair the same length 

    '''

    pass


def weight_set(factor=1.0):
    '''Set the weight of selected keys 

    :param factor: Factor, Interpolation factor between current brush weight, and keys’ weights 
    :type factor: float in [0, 1], (optional)
    '''

    pass
