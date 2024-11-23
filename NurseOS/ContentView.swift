//
//  ContentView.swift
//  NurseOS
//
//  Created by デジタルヘルス on 2024/11/22.
//



import SwiftUI
import AVFoundation

 struct ContentView: View {
     @State private var isAuthenticated = false
     @State private var isRecording = false
     @State private var showDatePicker = false
     @State private var recordDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
     @State private var patientName = ""
     @State private var patientID = ""
     @State private var audioRecorder: AVAudioRecorder?
     @State private var audioPlayer: AVAudioPlayer? // 音声再生用のプレーヤー
     @State private var showStopRecordingAlert = false
     @State private var recordedFileURL: URL? // 録音ファイルの保存URL

     var body: some View {
         VStack {
             if !isAuthenticated {
                 // 認証画面
                 VStack {
                     Text("患者認証")
                         .font(.title)
                         .padding()
                     
                     Button("認証") {
                         isAuthenticated = true
                     }
                     .padding()
                     .background(Color.blue)
                     .foregroundColor(.white)
                     .cornerRadius(10)
                 }
             } else {
                 VStack {
                     // 録音ボタンとカレンダーボタン
                     HStack {
                         Button(action: {
                             if isRecording {
                                 showStopRecordingAlert = true
                             } else {
                                 startRecording() // 録音開始
                             }
                         }) {
                             HStack {
                                 Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                     .font(.title2)
                                     .foregroundColor(isRecording ? .red : .blue)
                                 Text(isRecording ? "録音停止" : "録音開始")
                                     .fontWeight(.bold)
                                     .foregroundColor(.blue)
                             }
                         }
                         .padding()
                         .alert(isPresented: $showStopRecordingAlert) {
                             Alert(
                                 title: Text("録音停止の確認"),
                                 message: Text("録音を停止してもよろしいですか？"),
                                 primaryButton: .destructive(Text("はい")) {
                                     stopRecording() // 録音停止
                                 },
                                 secondaryButton: .cancel(Text("キャンセル"))
                             )
                         }
                         
                         Spacer()
                         
                         Button(action: {
                             withAnimation {
                                 showDatePicker.toggle()
                             }
                         }) {
                             Image(systemName: "calendar")
                                 .font(.title2)
                                 .padding()
                         }
                     }
                     .padding(.top)
                     
                     Text("看護記録")
                         .font(.largeTitle)
                         .bold()
                         .padding(.top)
                     
                     VStack(alignment: .leading, spacing: 10) {
                         HStack {
                             Text("記録日:")
                             Text("\(formattedDate(recordDate))")
                                 .onTapGesture {
                                     withAnimation {
                                         showDatePicker.toggle()
                                     }
                                 }
                         }
                         
                         Text("患者名: \(patientName.isEmpty ? "未入力" : patientName)")
                         Text("患者ID: \(patientID.isEmpty ? "未入力" : patientID)")
                     }
                     .padding()
                     
                     if showDatePicker {
                         VStack {
                             DatePicker(
                                 "記録日",
                                 selection: $recordDate,
                                 in: ...Date(), // 過去から現在の日付を選択可能
                                 displayedComponents: .date
                             )
                             .datePickerStyle(WheelDatePickerStyle())
                             .labelsHidden()
                             .environment(\.locale, Locale(identifier: "ja_JP"))
                             .frame(height: 150)

                             // 全体が青色のOKボタン
                             Button(action: {
                                 withAnimation {
                                     showDatePicker = false // カレンダーを閉じる
                                 }
                             }) {
                                 Text("OK")
                                     .font(.headline)
                                     .foregroundColor(.white) // テキスト色を白に設定
                                     .padding() // ボタンの余白を全体に追加（上下・左右）
                                     .background(Color.blue) // ボタン全体を青に設定
                                     .cornerRadius(20) // ボタンの角を丸める
                             }
                             .buttonStyle(PlainButtonStyle()) // ボタンのスタイルをプレーンにして余計なスタイルを除去
                             .frame(maxWidth: .infinity) // ボタン幅を調整
                         }
                     }


                     Form {
                         Section(header: Text("バイタルデータ")) {
                             TextField("血圧", text: .constant(""))
                             TextField("体温", text: .constant(""))
                             TextField("脈拍", text: .constant(""))
                         }
                         
                         Section(header: Text("看護記録 (SOAP)")) {
                             TextField("S: 主観的データ", text: .constant(""))
                             TextField("O: 客観的データ", text: .constant(""))
                             TextField("A: アセスメント", text: .constant(""))
                             TextField("P: 計画", text: .constant(""))
                         }
                     }

                     // 録音した音声ファイルを表示して、再生ボタンを追加
                     if let recordedFileURL = recordedFileURL {
                         VStack {
                             Text("録音ファイル: \(recordedFileURL.lastPathComponent)")
                                 .font(.footnote)
                                 .padding()

                             Button(action: {
                                 playAudio() // 音声を再生
                             }) {
                                 HStack {
                                     Image(systemName: "play.circle.fill")
                                     Text("再生")
                                         .fontWeight(.bold)
                                 }
                                 .foregroundColor(.blue)
                                 .padding()
                             }
                         }
                     }
                 }
                 .onAppear {
                     patientName = "山田 太郎"
                     patientID = "3849872"
                 }
             }
         }
     }
     
     func formattedDate(_ date: Date) -> String {
         let formatter = DateFormatter()
         formatter.dateFormat = "yy/MM/dd"
         return formatter.string(from: date)
     }
     
     func startRecording() {
         let audioSession = AVAudioSession.sharedInstance()
         
         // Vision OSのマイクへのアクセス許可をリクエスト
         audioSession.requestRecordPermission { granted in
             DispatchQueue.main.async {
                 if granted {
                     do {
                         // 録音用のセッションを設定
                         try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
                         try audioSession.setActive(true)
                         
                         // Vision OSで適切なマイクを選択
                         // ここではデフォルトのマイクを使用していますが、必要に応じて特定のマイクを指定できます
                         let audioFileName = getDocumentsDirectory().appendingPathComponent("input.wav")
                         
                         let settings: [String: Any] = [
                             AVFormatIDKey: Int(kAudioFormatLinearPCM),
                             AVSampleRateKey: 44100,
                             AVNumberOfChannelsKey: 1,
                             AVLinearPCMBitDepthKey: 16,
                             AVLinearPCMIsBigEndianKey: false,
                             AVLinearPCMIsFloatKey: false
                         ]
                         
                         // AVAudioRecorderのインスタンスを作成して録音を開始
                         audioRecorder = try AVAudioRecorder(url: audioFileName, settings: settings)
                         audioRecorder?.record()
                         
                         isRecording = true
                         recordedFileURL = audioFileName
                         print("録音が開始されました: \(audioFileName)")
                     } catch {
                         print("録音エラー: \(error.localizedDescription)")
                     }
                 } else {
                     print("マイクの使用が許可されていません")
                 }
             }
         }
     }
     
     func stopRecording() {
         audioRecorder?.stop()
         audioRecorder = nil
         isRecording = false
         print("録音が停止されました")
     }

     func playAudio() {
         guard let url = recordedFileURL else {
             print("録音ファイルが存在しません")
             return
         }
         
         do {
             audioPlayer = try AVAudioPlayer(contentsOf: url)
             audioPlayer?.play()
             print("音声再生開始: \(url)")
         } catch {
             print("音声再生エラー: \(error.localizedDescription)")
         }
     }

     func getDocumentsDirectory() -> URL {
         return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
     }
 }
