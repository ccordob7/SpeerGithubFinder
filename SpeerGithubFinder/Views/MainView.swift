//
//  MainView.swift
//  SpeerGithubFinder
//
//  Created by Camilo on 2025-04-05.
//

import SwiftUI

extension String: @retroactive Identifiable {
    public var id: String { self }
}

/*
 MainView. Class that contains a Github Image with a welcome text and a search bar to search for users on the app. This is the main Screen on the app
 */
struct MainView: View {
    @State private var UserName = ""
    @FocusState private var focus: Bool
    @State private var selectedUsername: String?
    
    var body: some View {
        //Main window Contains the App Main Page.
        NavigationStack {
            ZStack {
                Color.white
                
                //To beautify it, added Github logo Plus a welcome message
                Image("githubLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .padding(.top, -300)
                Text("Welcome To the Github User Finder App")
                    .padding(.top, -100)
                
                //Textfield used for searching the users
                TextField("Please type the username to search", text: $UserName)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onSubmit {
                        print(UserName)
                        selectedUsername = UserName
                    }
                    .focused($focus)
                
            }
            .onAppear {
                focus = true
            }
            .navigationDestination(item: $selectedUsername) { username in
                UserView(username: username)
            }
        }
    }
}

#Preview {
    MainView()
}
