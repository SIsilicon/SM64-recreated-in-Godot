tool
extends ImmediateGeometry

func _ready():
    clear()
    
    begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
    add_vertex(Vector3(-100,-100,0))
    add_vertex(Vector3(100,-100,0))
    add_vertex(Vector3(-100,100,0))
    add_vertex(Vector3(100,100,0))
    end()
    
    begin(Mesh.PRIMITIVE_POINTS)
    add_vertex(Vector3(1,1,1)*pow(2,16))
	add_vertex(-Vector3(1,1,1)*pow(2,16))
    end()
