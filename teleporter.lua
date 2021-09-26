fireBind = Input.Bind {
    Key = Keybinds.Fire1
}

throwBind = Input.Bind {
    Key = Keybinds.Fire2
}

fov = 0

-- GameObject refs
    model = nil
    screen1 = nil
    screen2 = nil
    screen3 = nil
    throwable = nil
    fx = nil
    trail = nil
    flare = nil
-- Teleporting vars
    teleportStart = nil
    teleportEnd = nil
    teleporting = false
    teleportingProgress = 0
    teleportingSpeed = 500
    enemyTarget = nil
--Slowmo vars
    slowmo = false
    slowmoInitial = 0.5
    slowmoRecoverSpeed = 2
    slowmoProgress = 0
--Flare flash vars
    flashing = false
    flashSpeed = 4
    flashProgress = 0
    lightIntensity = 0
-- Throwable vars
    throwStrength = 40
    throwPlayerVelMult = 0.66
-- Equip animation vars
    startRotation = Vector3.__new(59.709, 0, 0)
    endRotation = Vector3.zero
    activationAnimationPlaying = false
    activationAnimProgress = 0
    activationAnimPlaySpeed = 3
-- Screen FX vars
    t = 0
    lastSecond = 0
    screen = 1
    scale = nil
-- Sounds
    activationSound = nil
    deactivationSound = nil
    teleportSound = nil

function OnEnable()
    model = transform.Find("model")
    screen1 = transform.Find("model/screen1")
    screen2 = transform.Find("model/screen2")
    screen3 = transform.Find("model/screen3")
    throwable = transform.Find("throwable")
    light = transform.Find("model/model/light").GetComponent("Light")
    lightIntensity = light.intensity
    light.intensity = 0
    flare = transform.Find("model/flare").GetComponent("SpriteRenderer")
    flare.color = Color.__new(1,1,1,0)

    fov = Player.camera.FOV

    fx = transform.Find("fx").GetComponent("ParticleSystem")
    trail = fx.gameObject.GetComponent("TrailRenderer")
    fx.Play()
    trail.emitting = false
    fx.gameObject.layer = 8
    fx.emission.enabled = false;

    activationSound = transform.Find("act").GetComponent("AudioSource")
    deactivationSound = transform.Find("deact").GetComponent("AudioSource")
    teleportSound = transform.Find("teleport").GetComponent("AudioSource")

    activationSound.Play()

    model.localEulerAngles = startRotation
    activationAnimationPlaying = true
    activationAnimProgress = 0

    scale = Vector3.__new(0.1366631, 0.1303611, 0.2)

    screen1.gameObject.SetActive(true)
    screen2.gameObject.SetActive(true)
    screen3.gameObject.SetActive(true)
end

function Update(deltatime)
    if fireBind.wasPressedThisFrame then
        res = Physics.Raycast(Player.head.position + Player.head.forward, Player.head.forward, 1000, 4096)
        if res then enemyTarget = res.enemy end

        res = Physics.Raycast(Player.head.position + Player.head.forward, Player.head.forward, 1000, -65537)
        if res then
            teleportStart = Player.body.position
            teleportEnd = nil

            if enemyTarget then
                teleportEnd = enemyTarget.rigidbody.transform.position
            else
                teleportEnd = res.point + res.normal
            end

            teleporting = true
            trail.emitting = true
            fx.emission.enabled = true
            flashing = true
            flashProgress = -0.5
            Player.camera.Zoom(160)
            teleportingProgress = 0
            teleportSound.Play()
        end
    end

    ScreenFXRoutine(deltatime)
    if teleporting then TeleportRoutine(deltatime) end
    if slowmo then SlowmoRoutine(deltatime) end
    if flashing then FlashRoutine(deltatime) end
    if activationAnimationPlaying then AnimationRoutine(deltatime) end
end

function TeleportRoutine(deltatime)
    teleportingProgress = teleportingProgress + (deltatime * teleportingSpeed / Vector3.Distance(teleportStart, teleportEnd))
    Player.body.position = Vector3.Lerp(teleportStart, teleportEnd, teleportingProgress)
    if teleportingProgress >= 1 then
        if enemyTarget then
            enemyTarget.Explode()
            Player.styleHUD.AddPoints(300, "<color=#E6007E>PAULI'D</color>")
            Player.camera.CameraShake(1)
            enemyTarget = nil
        end
        fx.emission.enabled = false;
        trail.emitting = false
        teleporting = false
        Time.timeScale = slowmoInitial
        slowmoProgress = 0
        slowmo = true
    end
end

function FlashRoutine(deltatime)
    flare.color = Color.__new(1,1,1,1-flashProgress)
    light.intensity = 2.5*(1-flashProgress)
    if teleporting == false then flashProgress = flashProgress + deltatime * flashSpeed end
    if flashProgress >= 1 then 
        flashing = false
    end
end

function AnimationRoutine(deltatime)
    activationAnimProgress = activationAnimProgress + deltatime * activationAnimPlaySpeed;
    model.localEulerAngles = Vector3.Lerp(startRotation, endRotation, activationAnimProgress)
    if activationAnimProgress >= 1 then activationAnimationPlaying = false end
end

function SlowmoRoutine(deltatime)
    Time.timeScale = Mathf.Lerp(slowmoInitial, 1, slowmoProgress)
    slowmoProgress = slowmoProgress + Time.deltaTime * slowmoRecoverSpeed
    Player.camera.StopZoom()
    Player.camera.FOV = fov*(slowmoProgress*0.1+0.9)
    if Time.timeScale >= 1 then
        Player.camera.FOV = fov
        Time.timeScale = 1
        slowmo = false
    end
end

function ScreenFXRoutine(deltatime)
    if math.floor(t) ~= lastSecond then
        lastSecond = math.floor(t)    
        screen = screen + 1
        if screen == 4 then
            screen = 1
        end

        if screen == 1 then
            screen1.localScale = Vector3.zero
            screen2.localScale = scale
            screen3.localScale = Vector3.zero
        end
        if screen == 2 then
            screen1.localScale = Vector3.zero
            screen2.localScale = Vector3.zero
            screen3.localScale = scale
        end
        if screen == 3 then
            screen1.localScale = scale
            screen2.localScale = Vector3.zero
            screen3.localScale = Vector3.zero
        end
    end
    t = t + deltatime * 1.5
end
