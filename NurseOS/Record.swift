//
//  Record.swift
//  NurseOS
//
//  Created by デジタルヘルス on 2024/11/22.
//

import AVFoundation

func getDocumentsDirectory() -> URL {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}

func readPCMBuffer(url: URL) -> AVAudioPCMBuffer? {
    guard let input = try? AVAudioFile(forReading: url, commonFormat: .pcmFormatInt16, interleaved: false) else {
        return nil
    }
    guard let buffer = AVAudioPCMBuffer(pcmFormat: input.processingFormat, frameCapacity: AVAudioFrameCount(input.length)) else {
        return nil
    }
    do {
        try input.read(into: buffer)
    } catch {
        return nil
    }
    return buffer
}

func writePCMBuffer(url: URL, buffer: AVAudioPCMBuffer) throws {
    let settings: [String: Any] = [
        AVFormatIDKey: buffer.format.settings[AVFormatIDKey] ?? kAudioFormatLinearPCM,
        AVNumberOfChannelsKey: buffer.format.settings[AVNumberOfChannelsKey] ?? 2,
        AVSampleRateKey: buffer.format.settings[AVSampleRateKey] ?? 44100,
        AVLinearPCMBitDepthKey: buffer.format.settings[AVLinearPCMBitDepthKey] ?? 16
    ]

    do {
        let output = try AVAudioFile(forWriting: url, settings: settings, commonFormat: .pcmFormatInt16, interleaved: false)
        try output.write(from: buffer)
    } catch {
        throw error
    }
}

func copyPCMBuffer(from inputPath: String, to outputPath: String) {
    // ファイルパスの取得
    let inputURL = getDocumentsDirectory().appendingPathComponent(inputPath)
    let outputURL = getDocumentsDirectory().appendingPathComponent(outputPath)
    
    guard let inputBuffer = readPCMBuffer(url: inputURL) else {
        fatalError("Failed to read \(inputPath)")
    }
    guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: inputBuffer.format, frameCapacity: inputBuffer.frameLength) else {
        fatalError("Failed to create a buffer for writing")
    }
    guard let inputInt16ChannelData = inputBuffer.int16ChannelData else {
        fatalError("Failed to obtain underlying input buffer")
    }
    guard let outputInt16ChannelData = outputBuffer.int16ChannelData else {
        fatalError("Failed to obtain underlying output buffer")
    }
    
    for channel in 0 ..< Int(inputBuffer.format.channelCount) {
        let p1: UnsafeMutablePointer<Int16> = inputInt16ChannelData[channel]
        let p2: UnsafeMutablePointer<Int16> = outputInt16ChannelData[channel]

        for i in 0 ..< Int(inputBuffer.frameLength) {
            p2[i] = p1[i]
        }
    }

    outputBuffer.frameLength = inputBuffer.frameLength

    do {
        try writePCMBuffer(url: outputURL, buffer: outputBuffer)
        print("保存が完了しました: \(outputURL)")
    } catch {
        fatalError("Failed to write \(outputPath): \(error)")
    }
}

func main() {
    // 入出力ファイル名を指定して呼び出す
    copyPCMBuffer(from: "input.wav", to: "output.wav")
}
