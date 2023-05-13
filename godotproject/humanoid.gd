extends CharacterBody3D

@onready var armature = $Armature
@onready var spring_arm_pivot = $SpringArmPivot
@onready var spring_arm = $SpringArmPivot/SpringArm3D
@onready var animation_tree = $AnimationTree
@onready var skeleton = $Armature/Skeleton3D

const MAX_SPEED = 5.0
const JUMP_VELOCITY = 5.5
const LERP_VAL = 0.15
const FALLING_THRESHOLD_SECONDS = 2.0 # Play falling animation after falling this long

var hang_time = 0;

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func switch_mesh(index):
    # var meshes = [m for m in get_children() if m is MeshInstance3D]
    var meshes = []
    for child in skeleton.get_children():
        if child is MeshInstance3D:
            meshes.append(child)

    for i in meshes.size():
        if(i == index): meshes[i].show()
        else: meshes[i].hide()
        

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    
    switch_mesh(0)

# Capture mouse as a result of an input (browser restriction)
# See: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html#full-screen-and-mouse-capture
# TODO: Allow for recapture if the user Escs out of capture.
var captureMouse = false
func _input(event):
    if event is InputEventMouseButton and not captureMouse:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
        captureMouse = true

func _unhandled_input(event):
    if Input.is_action_just_pressed("quit"):
        get_tree().quit()
        
    if event is InputEventMouseMotion:
        spring_arm_pivot.rotate_y(-event.relative.x * 0.005)
        spring_arm.rotate_x(-event.relative.y * 0.005)
        
        # Clamp looking up and down. Comment this out for some fun:
        spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/4, PI/4)

func _physics_process(delta):
    
    # Add the gravity.
    if is_on_floor():
        hang_time = 0;
    else:
        velocity.y -= gravity * delta
        hang_time += delta;

    # Switch characters
    if Input.is_action_just_pressed("character_1"):
        switch_mesh(0)
    elif Input.is_action_just_pressed("character_2"):
        switch_mesh(1)

    # Handle Jump.
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY
        
        # TODO: Unjank animation
        $AnimationTree.set("parameters/jump/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

    # Set falling animation
    if hang_time > FALLING_THRESHOLD_SECONDS and not (animation_tree.get("parameters/fall/active")):
        $AnimationTree.set("parameters/fall/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

    # Unset jumping and falling when on the ground
    if is_on_floor() and (animation_tree.get("parameters/jump/active") or animation_tree.get("parameters/fall/active")):
        $AnimationTree.set("parameters/jump/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
        $AnimationTree.set("parameters/fall/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)

    # Get the input direction and handle the movement/deceleration.
    var input_dir = Input.get_vector("left", "right", "forward", "back")
    
    var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    direction = direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)
    
    var speed = MAX_SPEED if not Input.is_action_pressed("walk") else MAX_SPEED / 3
    
    if direction:
        velocity.x = lerp(velocity.x, direction.x * speed, LERP_VAL)
        velocity.z = lerp(velocity.z, direction.z * speed, LERP_VAL)
        armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), LERP_VAL)
    else:
        velocity.x = lerp(direction.x, 0.0, LERP_VAL)
        velocity.z = lerp(direction.z, 0.0, LERP_VAL)

    # print(velocity.length() / MAX_SPEED)
    animation_tree.set("parameters/walkrun/blend_position", velocity.length() / MAX_SPEED)

    move_and_slide()
