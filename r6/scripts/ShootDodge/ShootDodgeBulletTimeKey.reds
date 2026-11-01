// ShootDodge (C2SD-T37): Bullet Time mode's default key (Numpad Enter) through a game input action.
//
// r6/input/ShootDodge.xml (loaded by the Input Loader mod) defines the action ShootDodgeBulletTime,
// mapped to IK_Enter in the on-foot Locomotion context. This file only listens for it: every fresh
// press is counted here, and the CET side (modules/BulletTimeKeyDriver.lua) takes the count each
// frame through Game.GetScriptableSystemsContainer():Get("ShootDodgeBulletTimeKeySystem") and
// toggles Bullet Time mode, debounced against the CET binding. Without Input Loader the action never
// fires and nothing here does anything; the file needs nothing but redscript.

public class ShootDodgeBulletTimeKeyListener {
  private let m_owner: wref<ShootDodgeBulletTimeKeySystem>;

  public func SetOwner(owner: ref<ShootDodgeBulletTimeKeySystem>) -> Void {
    this.m_owner = owner;
  }

  protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
    if Equals(ListenerAction.GetName(action), n"ShootDodgeBulletTime")
        && ListenerAction.IsButtonJustPressed(action) {
      let owner: ref<ShootDodgeBulletTimeKeySystem> = this.m_owner;
      if IsDefined(owner) {
        owner.OnKeyPressed();
      };
    };
    return false;
  }
}

public class ShootDodgeBulletTimeKeySystem extends ScriptableSystem {
  private let m_listener: ref<ShootDodgeBulletTimeKeyListener>;
  private let m_player: wref<PlayerPuppet>;
  private let m_pending: Int32;
  private let m_total: Int32;

  public static func Get(gi: GameInstance) -> ref<ShootDodgeBulletTimeKeySystem> {
    return GameInstance.GetScriptableSystemsContainer(gi).Get(n"ShootDodgeBulletTimeKeySystem") as ShootDodgeBulletTimeKeySystem;
  }

  // Called when the player puppet attaches (each session start). Moves the listener to it.
  public func Attach(player: ref<PlayerPuppet>) -> Void {
    if !IsDefined(this.m_listener) {
      this.m_listener = new ShootDodgeBulletTimeKeyListener();
      this.m_listener.SetOwner(this);
    };
    let previous: ref<PlayerPuppet> = this.m_player;
    if IsDefined(previous) {
      previous.UnregisterInputListener(this.m_listener, n"ShootDodgeBulletTime");
    };
    player.RegisterInputListener(this.m_listener, n"ShootDodgeBulletTime");
    this.m_player = player;
    this.m_pending = 0;
  }

  public func OnKeyPressed() -> Void {
    this.m_pending += 1;
    this.m_total += 1;
  }

  // ---- CET side ----

  // Presses since the last call (normally 0 or 1), then forgets them.
  public func TakePresses() -> Int32 {
    let count: Int32 = this.m_pending;
    this.m_pending = 0;
    return count;
  }

  public func TotalPresses() -> Int32 {
    return this.m_total;
  }

  public func IsListening() -> Bool {
    return IsDefined(this.m_player);
  }
}

@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let ret: Bool = wrappedMethod();
  let system: ref<ShootDodgeBulletTimeKeySystem> = ShootDodgeBulletTimeKeySystem.Get(this.GetGame());
  if IsDefined(system) {
    system.Attach(this);
  };
  return ret;
}
