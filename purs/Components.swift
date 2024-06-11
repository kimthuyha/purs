//
//  Components.swift
//  purs
//
//  Created by Kim Thuy Ha on 6/7/24.
//

import SwiftUI

struct Header: View {
    @StateObject var viewModel : LocationDetailsViewModel
    var body:some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(gradient: Gradient(colors: [.black.opacity(0.85), .clear]), startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
                .frame(height:250)
            
            Text(viewModel.locationName)
                .font(.custom("FiraSans-Black", size: 54))
                .foregroundColor(Color.white)
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
                .padding(.horizontal, 23)
                .padding(.top, 21)
        }
    }
}

struct Footer: View {
    var body:some View {
        ZStack(alignment: .bottom) {
            LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.85)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(.all)
                .frame(height: 123)
            VStack {
                Spacer(minLength: 20)
                Image(systemName: "chevron.up")
                    .foregroundColor(.white) // Adjust color as needed
                    .font(.system(size: 15, weight: .bold)) // Set size and weight to bold
                    .opacity(0.5) // Set opacity to 50%
                    .padding(.bottom, 5)
                Image(systemName: "chevron.up")
                    .foregroundColor(.white) // Adjust color as needed
                    .font(.system(size: 15, weight: .bold)) // Set size and weight to bold
                    .padding(.bottom, 5)
                
                Text("View Menu")
                    .font(.custom("HindSiliguri-Regular", size: 24))
                    .foregroundColor(Color.white)
                    .ignoresSafeArea(.all)
                    .edgesIgnoringSafeArea(.bottom)
                Spacer().frame(height:20)
                
            }
        }
    }
}

struct OpeningHoursCard: View {
    @StateObject var viewModel : LocationDetailsViewModel
    let dayOfWeek = Calendar.current.component(.weekday, from: Date())
    var body: some View {
        
        VStack {
            VStack (alignment: .leading, spacing: 0) {
                
                Message(viewModel: viewModel)
                
                if viewModel.isExpanded{
                    Divider()
                        .background(Color.black.opacity(0.25))
                        .padding(.top,10)
                    HoursList(viewModel: viewModel)
                        .padding(.top,10)
                        .frame(height:275)
                }
                
            }
            .padding(.vertical,12)
            .padding(.horizontal, 15)
            .onTapGesture {
                withAnimation {
                    viewModel.isExpanded.toggle()
                }
            }
            .background(ZStack{
                RoundedRectangle(cornerRadius: 8) // Background shape
                    .fill(Color(red: 0.851, green: 0.851, blue: 0.851, opacity: 0.85)) // Set background color
                RoundedRectangle(cornerRadius: 8) // Shadow shape (invisible)
                    .fill(Color.clear)
                    .shadow(color: Color.black.opacity(0.25), radius: 10.2, x: 0, y: 4) // Apply shadow
            })
            
        }.padding(.horizontal, 23)
    }
    
}

struct HoursList: View {
    let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    @StateObject var viewModel : LocationDetailsViewModel
    var body:some View {
        // Get the current day index
        let calendar = Calendar.current
        let currentWeekdayIndex = (calendar.component(.weekday, from: Date()) + 5) % 7 // Adjust for Monday start
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(0..<weekdays.count, id: \.self) { index in // Iterate over the range of weekdays array indices
                    // Check if day exists in data
                    HStack(alignment: .top) { // Align day and hours to the top
                        Text(weekdays[index]).bold(index == currentWeekdayIndex)
                        Spacer()
                        if viewModel.formattedHours[index].count > 0 {
                            VStack(alignment: .trailing) { // Stack hours vertically
                                ForEach(viewModel.formattedHours[index], id: \.self) { hour in
                                    Text(hour).padding(0.5).bold(index == currentWeekdayIndex)
                                }
                            }
                        } else {
                            Text("Closed").bold(index == currentWeekdayIndex)
                        }
                    }
                    .padding(.bottom, 10) // Add some spacing between each day
                    
                }
            }
        }
    }
}

struct Message: View {
    @StateObject var viewModel : LocationDetailsViewModel
    var body:some View {
        HStack{
            VStack (alignment: .leading, spacing: 0) {
                HStack {
                    Text(viewModel.msg.formatMessage())
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                        .font(.custom("HindSiliguri-Regular", size: 18))
                        .lineLimit(1) // Prevent text from wrapping
                        .fixedSize(horizontal: true, vertical: false) // Ensure it stays on one line
                    
                    Circle()
                        .fill(viewModel.msg.getColor())
                        .fixedSize()
                }
                
                Text("SEE FULL HOURS")
                    .foregroundColor(Color(hex: "#333333").opacity(0.7))
                    .font(.custom("Chivo-Regular", size: 12))
            }
            Spacer()
            if viewModel.isExpanded {
                Image(systemName: "chevron.up")
                    .foregroundColor(Color(hex: "#333333"))
                    .font(.system(size: 13, weight: .bold)) // Set size and weight
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(hex: "#333333"))
                    .font(.system(size: 15, weight: .bold)) // Set size and weight
            }
            
        }
    }
}


extension Color {
    init(hex: String) {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanHex = cleanHex.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&rgb)
        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

