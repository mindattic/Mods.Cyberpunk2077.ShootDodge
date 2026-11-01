// ShootDodge (C2SD-T27): the "Max Payne" contact in V's phone, whose text thread explains the mod.
//
// A real phone text in the Messages app, through the Phone Extension framework (Nexus mod 24949,
// by r457 & gh057), which this file requires along with redscript. The words live in the CET side
// (bin/x64/plugins/cyber_engine_tweaks/mods/ShootDodge/modules/IntroMessage.lua); every session
// that Lua side fills this system's thread through ClearThread/AddMessage/SetUnread, and only the
// first time on a save (quest fact shootdodge_intro_message unset) does it call Notify, so the HUD
// "new message" pops once per save while the thread itself stays in the phone like any other SMS.
// Opening the thread marks it read in the save (fact = 2).
//
// The contact uses only an existing in-game avatar (PhoneAvatars.Avatar_Unknown) and is hidden
// until the thread has been filled.

import PhoneExtension.Classes.*
import PhoneExtension.System.*

public class ShootDodgeMaxPayneContact extends PhoneEventsListener {
  private let m_owner: wref<ShootDodgePhoneSystem>;

  public func SetOwner(owner: ref<ShootDodgePhoneSystem>) -> Void {
    this.m_owner = owner;
  }

  public func GetContactHash() -> Int32 {
    return 271027001;
  }

  public func GetContactData(isText: Bool) -> ref<ContactData> {
    let owner: ref<ShootDodgePhoneSystem> = this.m_owner;
    // Messages tab only (no call entry), and only once the thread exists.
    if !isText || !IsDefined(owner) || !owner.HasThread() {
      return null;
    };
    let data: ref<ContactData> = new ContactData();
    data.hash = this.GetContactHash();
    data.localizedName = owner.SenderName();
    data.contactId = "ShootDodge_MaxPayne";
    data.id = "SDMAXPAYNE";
    data.avatarID = t"PhoneAvatars.Avatar_Unknown";
    data.questRelated = false;
    data.isCallable = false;
    data.type = MessengerContactType.SingleThread;
    data.lastMesssagePreview = owner.LastMessage();
    data.messagesCount = owner.MessageCount();
    data.hasMessages = true;
    data.playerIsLastSender = false;
    if owner.IsUnread() {
      data.unreadMessegeCount = 1;
      ArrayPush(data.unreadMessages, 1);
    };
    return data;
  }

  public func ShowDialog(messengerController: wref<MessengerDialogViewController>) -> Bool {
    let owner: ref<ShootDodgePhoneSystem> = this.m_owner;
    if !IsDefined(owner) || !owner.HasThread() {
      return false;
    };
    let count: Int32 = owner.MessageCount();
    let i: Int32 = 0;
    while i < count {
      messengerController.PushMessageCustom(owner.MessageAt(i), MessageViewType.Received,
        owner.SenderName(), i == count - 1);
      i += 1;
    };
    messengerController.m_scrollController.SetScrollPosition(1.00);
    owner.MarkRead();
    return true;
  }
}

public class ShootDodgePhoneSystem extends ScriptableSystem {
  private let m_contact: ref<ShootDodgeMaxPayneContact>;
  private let m_sender: String;
  private let m_messages: array<String>;
  private let m_unread: Bool;
  private let m_phoneReady: Bool;

  public static func Get(gi: GameInstance) -> ref<ShootDodgePhoneSystem> {
    return GameInstance.GetScriptableSystemsContainer(gi).Get(n"ShootDodgePhoneSystem") as ShootDodgePhoneSystem;
  }

  public func Contact() -> ref<ShootDodgeMaxPayneContact> {
    if !IsDefined(this.m_contact) {
      this.m_contact = new ShootDodgeMaxPayneContact();
      this.m_contact.SetOwner(this);
    };
    return this.m_contact;
  }

  // ---- CET side (modules/IntroMessageDriver.lua) ----

  // True once the HUD phone is up and the contact is registered with Phone Extension.
  public func IsPhoneReady() -> Bool {
    return this.m_phoneReady;
  }

  public func ClearThread(sender: String) -> Void {
    ArrayClear(this.m_messages);
    this.m_sender = sender;
    this.m_unread = false;
  }

  public func AddMessage(text: String) -> Void {
    ArrayPush(this.m_messages, text);
  }

  public func SetUnread(unread: Bool) -> Void {
    this.m_unread = unread;
  }

  // The HUD "new message" notification (opens the thread when used). Returns false if the phone
  // isn't ready or the thread is empty, so the caller can try again later.
  public func Notify(title: String, text: String) -> Bool {
    if !this.m_phoneReady || !this.HasThread() {
      return false;
    };
    let player: ref<GameObject> = GameInstance.GetPlayerSystem(this.GetGameInstance()).GetLocalPlayerMainGameObject();
    if !IsDefined(player) {
      return false;
    };
    let phone: ref<PhoneExtensionSystem> = PhoneExtensionSystem.GetInstance(player);
    if !IsDefined(phone) {
      return false;
    };
    phone.NotifyNewMessageCustom(this.Contact().GetContactHash(), title, text);
    return true;
  }

  // ---- Contact side ----

  public func HasThread() -> Bool {
    return ArraySize(this.m_messages) > 0;
  }

  public func MessageCount() -> Int32 {
    return ArraySize(this.m_messages);
  }

  public func MessageAt(index: Int32) -> String {
    return this.m_messages[index];
  }

  public func LastMessage() -> String {
    let count: Int32 = ArraySize(this.m_messages);
    if count == 0 {
      return "";
    };
    return this.m_messages[count - 1];
  }

  public func SenderName() -> String {
    if StrLen(this.m_sender) == 0 {
      return "Max Payne";
    };
    return this.m_sender;
  }

  public func IsUnread() -> Bool {
    return this.m_unread;
  }

  // Opening the thread marks it read for this save, so the next session shows it as read too.
  public func MarkRead() -> Void {
    if this.m_unread {
      this.m_unread = false;
      GameInstance.GetQuestsSystem(this.GetGameInstance()).SetFact(n"shootdodge_intro_message", 2);
    };
  }

  // ---- HUD phone lifecycle ----

  public func OnPhoneUp(controller: ref<NewHudPhoneGameController>) -> Void {
    let phone: ref<PhoneExtensionSystem> = PhoneExtensionSystem.GetInstance(controller.GetPlayerControlledObject());
    if !IsDefined(phone) {
      this.m_phoneReady = false;
      return;
    };
    phone.Unregister(this.Contact());
    phone.Register(this.Contact());
    this.m_phoneReady = true;
  }

  public func OnPhoneDown(controller: ref<NewHudPhoneGameController>) -> Void {
    this.m_phoneReady = false;
    let phone: ref<PhoneExtensionSystem> = PhoneExtensionSystem.GetInstance(controller.GetPlayerControlledObject());
    if IsDefined(phone) {
      phone.Unregister(this.Contact());
    };
  }
}

@wrapMethod(NewHudPhoneGameController)
protected cb func OnInitialize() -> Bool {
  let ret: Bool = wrappedMethod();
  let player: ref<GameObject> = this.GetPlayerControlledObject();
  if IsDefined(player) {
    let system: ref<ShootDodgePhoneSystem> = ShootDodgePhoneSystem.Get(player.GetGame());
    if IsDefined(system) {
      system.OnPhoneUp(this);
    };
  };
  return ret;
}

@wrapMethod(NewHudPhoneGameController)
protected cb func OnUninitialize() -> Bool {
  let ret: Bool = wrappedMethod();
  let player: ref<GameObject> = this.GetPlayerControlledObject();
  if IsDefined(player) {
    let system: ref<ShootDodgePhoneSystem> = ShootDodgePhoneSystem.Get(player.GetGame());
    if IsDefined(system) {
      system.OnPhoneDown(this);
    };
  };
  return ret;
}
