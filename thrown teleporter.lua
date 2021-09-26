rb = nil
gravCompensation = 0.5

function OnEnable()
	rb = transform.GetComponent("Rigidbody")
	gameObject.layer = 14
	rb.velocity = rb.velocity + Vector3.up * gravCompensation
	rb.angularVelocity = Vector3.__new(Random.Range(0,10), Random.Range(0,10), Random.Range(0,10))
end

function Update()
end