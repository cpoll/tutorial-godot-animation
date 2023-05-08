extends CharacterBody3D

@onready var armature = $Armature
@onready var spring_arm_pivot = $SpringArmPivot
@onready var spring_arm = $SpringArmPivot/SpringArm3D
@onready var animation_tree = $AnimationTree

const MAX_SPEED = 5.0
const JUMP_VELOCITY = 5.5
const LERP_VAL = 0.15

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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
    if not is_on_floor():
        velocity.y -= gravity * delta

    # Handle Jump.
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY
        
        # TODO: Unjank animation
        $AnimationTree.set("parameters/jump/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

    # Set falling animation
    if not is_on_floor() and not (animation_tree.get("parameters/fall/active") or animation_tree.get("parameters/jump/active")):
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

    print(velocity.length() / MAX_SPEED)
    animation_tree.set("parameters/walkrun/blend_position", velocity.length() / MAX_SPEED)

    move_and_slide()
