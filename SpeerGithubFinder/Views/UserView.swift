//
//  UserView.swift
//  SpeerGithubFinder
//
//  Created by Camilo on 2025-04-05.
//

import SwiftUI

/*
 UserView. Class that contains and handles the displaying of a selected user when given a user name
 This View displays the Github User Avatar in a circle shape, followed by its name, their username, their Bio/Description followed by 2 buttons, followers and following as requested in teh excercise.
 This page can also be pulled down to refresh, which loads the user again.
 */
struct UserView: View {
    let username: String
    
    //User variables to display info
    @State private var user: GitHubUser?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView{
            Group{
                //Loading bar for API call, as api gets called on view Load
                if isLoading {
                    ProgressView("Looking for User")
                } else if let user = user {
                    //User display created in displayGitHubUser method for code cleanliness
                    displayGitHubUser(for: user)
                }else {
                    //Error page, to display an error if no user was found
                    displayErrorPage()
                }
            }.frame(maxWidth: .infinity)
        }
        .refreshable {
            loadUser(forceRefresh: true)
        }
        .onAppear {
            loadUser()
        }
        .navigationTitle(username)
        .navigationBarTitleDisplayMode(.inline)
        .padding()
    }
    
    /**
     func loadUser() -> void
     - parameter forceRefresh: Flag to force a cache refresh
     Private function. This Function connects to the GitHubServiceController, and asks for the API call results, following MVC patterns.
     The results are saved into the user variable to be displayed on the screen, and saves the error messages to display if needed
     */
    private func loadUser(forceRefresh: Bool = false) {
            GitHubServiceController.shared.fetchUser(username: username, forceRefresh: forceRefresh) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    switch result {
                    case .success(let fetchedUser):
                        self.user = fetchedUser
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    
    /**
     displayGitHubUser(for user: GitHubUser) -> View
     - parameter user: Obtained GitHubUser to display
     - returns: View of the user
     This function obtains the converted GitHubUser data from the API and uses it to display the Avatar, name, username, bio, followers and following from a user.
     */
    func displayGitHubUser(for user: GitHubUser) -> some View {
        VStack(spacing: 10) {
            //Get Image and assign it as a Rezisable image in the page
            AsyncImage(url: URL(string: user.avatar_url)) {
                image in image.image?.resizable()
            }
            .frame(width: 200, height: 200)
            .clipShape(Circle())
            .padding(.top)
            
            //Setup Name, User Name and Bio/Description
            Text(user.name ?? "Not Found")
                .font(.title2)
                .bold()
            Text("@" + user.login)
            Text(user.bio ?? "No Description/Bio Available")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            HStack {
                Button(action: {
                                    
                }) {
                    NavigationLink(destination: UserListView(user: user, listType: .followers)) {
                        Text("\(user.followers) Followers")
                            .foregroundColor(.blue)
                    }
                }
                Spacer()
                Button(action: {
                                  
                }) {
                    NavigationLink(destination: UserListView(user: user, listType: .following)) {
                        Text("\(user.following) Following")
                            .foregroundColor(.blue)
                    }
                }
            }
                .padding(.horizontal)
                .font(.subheadline)
            Spacer()
        }
    }
    
    /**
     func displayErrorPage() -> some View
     - returns: Error screen View
     This function displays an error Screen indicating that there was not an user with the name or an api error
     */
    func displayErrorPage() -> some View {
        VStack (spacing: 5) {
            Image("errorImage")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
            Text("User not found")
                .foregroundColor(.red)
            
            Text("Please Verify Name and Try Again")
            Spacer()
            Spacer()
            Spacer()
            Text("Error: \(errorMessage ?? "Unable to fetch Error")")
                .foregroundColor(.red)
        }
    }
}

//Preview Screen for XCode. Change username to debug dynamically. Using Octocat as default
#Preview {
    //Using Default User as TheOctocat Mascot User for preview screen
    UserView(username: "octocat")
}
