//
//  ViewController.swift
//  ZIMKitDemo
//
//  Created by Kael Ding on 2023/3/22.
//

import UIKit
import ZIMKit
import ZIM
import ZegoUIKitPrebuiltCall
import ZegoUIKitSDK

let appID: UInt32 = YOUR_APPID
let appSign: String = YOUR_APP_SIGN

class ViewController: UIViewController {
    
    @IBOutlet weak var userIDTextField: UITextField!
    @IBOutlet weak var userNameTextField: UITextField!
    
    var selfUserID = UserDefaults.standard.string(forKey: "userID") ?? String(UInt32.random(in: 1000..<10000))
    var selfUserName = UserDefaults.standard.string(forKey: "userName") ?? randomName()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // zimkit init and login.
        ZIMKit.initWith(appID: appID, appSign: appSign)
        
        userIDTextField.text = selfUserID
        userNameTextField.text = selfUserName
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        ZIMKit.disconnectUser()
    }
    
    
    @IBAction func userIDChanged(_ sender: UITextField) {
        selfUserID = sender.text ?? "123456"
    }
    
    @IBAction func userNameChanged(_ sender: UITextField) {
        selfUserName = sender.text ?? "Tina"
    }
    
    
    @IBAction func login(_ sender: Any) {
        
        UserDefaults.standard.set(selfUserID, forKey: "userID")
        UserDefaults.standard.set(selfUserName, forKey: "userName")
        
        let avatarUrl = "https://storage.zego.im/IMKit/avatar/avatar-0.png"
        ZIMKit.connectUser(userID: selfUserID, userName: selfUserName, avatarUrl: avatarUrl) { error in
            if error.code != .success {
                return
            }
            self.showConversationList()
        }
        
        // Call init
        let config = ZegoUIKitPrebuiltCallInvitationConfig(notifyWhenAppRunningInBackgroundOrQuit: false, isSandboxEnvironment: true)
        ZegoUIKitPrebuiltCallInvitationService.shared.initWithAppID(appID, appSign: appSign, userID: self.selfUserID, userName: self.selfUserName, config: config)
    }
    
    func showConversationList() {
        let vc = ZIMKitConversationListVC()
        vc.messageDelegate = self
        vc.delegate = self
        
        navigationController?.pushViewController(vc, animated: true)
        
        // add a action
        let action = UIAction { action in
            self.startChatActions()
        }
        let item = UIBarButtonItem(systemItem: .add, primaryAction: action)
        vc.navigationItem.rightBarButtonItem = item
    }
}

// MARK: - Start a chat
extension ViewController {
    func startChat(_ conversationID: String, _ type: ZIMConversationType) {
        let inputConfig = InputConfig(showVoiceButton: true, showEmojiButton: true, showAddButton: true);
        let vc = ZIMKitMessagesListVC(conversationID: conversationID, type: type, inputConfig: inputConfig)
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func createGroup(_ groupName: String, _ groupID: String, _ userIDs: [String]) {
        ZIMKit.createGroup(with: groupName, groupID: groupID, inviteUserIDs: userIDs) { groupInfo, inviteUserErrors, error in
            if error.code == .success {
                self.startChat(groupInfo.id, .group)
            }
        }
    }
    
    func joinGroup(_ groupID: String) {
        ZIMKit.joinGroup(by: groupID) { groupInfo, error in
            if error.code == .success || error.code == .groupModuleMemberIsAlreadyInTheGroup {
                self.startChat(groupID, .group)
            }
        }
    }
}


// MARK: - Chat action
extension ViewController {
    
    func startChatActions() {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let action1 = UIAlertAction(title: "New Chat", style: .default) { _ in
            self.startSingleChatAction()
        }
        
        let action2 = UIAlertAction(title: "New Group", style: .default) { _ in
            self.createGroupAction()
        }
        
        let action3 = UIAlertAction(title: "Join Group", style: .default) { _ in
            self.joinGroupAction()
        }
        
        let action4 = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(action1)
        alert.addAction(action2)
        alert.addAction(action3)
        alert.addAction(action4)
        
        UIApplication.topViewController()?.present(alert, animated: true)
    }
    
    func startSingleChatAction() {
        let alert = UIAlertController(title: "New Chat", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "User ID"
        }
        let action1 = UIAlertAction(title: "OK", style: .default) { _ in
            let conversationID = alert.textFields?.first?.text ?? ""
            self.startChat(conversationID, .peer)
        }
        let action2 = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(action1)
        alert.addAction(action2)
        UIApplication.topViewController()?.present(alert, animated: true)
    }
    
    func createGroupAction() {
        let alert = UIAlertController(title: "New Group", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Group Name"
        }
        alert.addTextField { textField in
            textField.placeholder = "Group ID (Optional)"
        }
        alert.addTextField { textField in
            textField.placeholder = "Invite User IDs (eg. 123;456)"
        }
        let action1 = UIAlertAction(title: "OK", style: .default) { _ in
            let groupName = alert.textFields?[0].text ?? "Test Group"
            let groupID = alert.textFields?[1].text ?? ""
            let text = alert.textFields?[2].text ?? ""
            let userIDs = text.components(separatedBy: ";")
            self.createGroup(groupName, groupID, userIDs)
        }
        let action2 = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(action1)
        alert.addAction(action2)
        UIApplication.topViewController()?.present(alert, animated: true)
    }
    
    func joinGroupAction() {
        let alert = UIAlertController(title: "Join Group", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Group ID"
        }
        let action1 = UIAlertAction(title: "OK", style: .default) { _ in
            let groupID = alert.textFields?.first?.text ?? ""
            self.joinGroup(groupID)
        }
        let action2 = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(action1)
        alert.addAction(action2)
        UIApplication.topViewController()?.present(alert, animated: true)
    }
}

// MARK: - Call
extension ViewController: ZIMKitMessagesListVCDelegate, ZIMKitConversationListVCDelegate {
    func conversationList(_ conversationListVC: ZIMKitConversationListVC, didSelectWith conversation: ZIMKitConversation, defaultAction: () -> ()) {
        
        let inputConfig = InputConfig(showVoiceButton: true,
                                      showEmojiButton: true,
                                      showAddButton: true)
        
        let messageListVC = ZIMKitMessagesListVC(conversationID: conversation.id,
                                                 type: conversation.type,
                                                 conversationName: conversation.name,
                                                 inputConfig: inputConfig)
        messageListVC.delegate = self
        self.navigationController?.pushViewController(messageListVC, animated: true)
    }
    
    func getMessageListHeaderBar(_ messageListVC: ZIMKitMessagesListVC) -> ZIMKitHeaderBar? {
        
        if messageListVC.conversationType != .peer { return nil }
        
        let header = ZIMKitHeaderBar()
        
        let conversationID = messageListVC.conversationID
        let conversationName = messageListVC.conversationName
        
        let voiceCallButton: ZegoSendCallInvitationButton = ZegoSendCallInvitationButton(ZegoInvitationType.voiceCall.rawValue)
        voiceCallButton.inviteeList = [ZegoUIKitUser(conversationID, conversationName)]
        
        let videoCallButton: ZegoSendCallInvitationButton = ZegoSendCallInvitationButton(ZegoInvitationType.videoCall.rawValue)
        videoCallButton.inviteeList = [ZegoUIKitUser(conversationID, conversationName)]
        
        let voiceItem = UIBarButtonItem(customView: voiceCallButton)
        let videoItem = UIBarButtonItem(customView: videoCallButton)
        
        header.rightItems = [videoItem, voiceItem]
        
        return header
    }
}

