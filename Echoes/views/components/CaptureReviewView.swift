//
//  CaptureReviewView.swift
//  Echoes
//

import SwiftUI

/// 拍照后的结果确认页。
///
/// 这一步是新增的：重构前识别完直接静默入库，用户看不到判成了什么表情。
struct CaptureReviewView: View {

    @Environment(CaptureCoordinator.self) private var capture
    @Environment(\.dismiss) private var dismiss

    let image: UIImage
    let report: EmotionReport

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    photo

                    verdict

                    EmotionScoreBars(scores: report.rankedScores, highlight: report.emotion)
                        .padding(.horizontal)

                    if let reason = report.degradedReason {
                        degradedNotice(reason)
                    } else if report.isLowConfidence {
                        lowConfidenceNotice
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(L10n.reviewTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.retake) {
                        capture.discardPendingMemory()
                    }
                    .disabled(capture.phase == .saving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.save) {
                        Task { await capture.savePendingMemory() }
                    }
                    .fontWeight(.semibold)
                    .disabled(capture.phase == .saving)
                }
            }
            .overlay {
                if capture.phase == .saving {
                    savingOverlay
                }
            }
        }
        .interactiveDismissDisabled(capture.phase == .saving)
    }

    // MARK: - 片段

    private var photo: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 360)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.quaternary, lineWidth: 1)
            )
            .padding(.horizontal)
    }

    private var verdict: some View {
        HStack(spacing: 12) {
            Image(systemName: report.emotion.symbol)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(report.emotion.tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(report.emotion.displayName)
                    .appText(24, weight: .bold)
                Text(L10n.memoryConfidence(report.confidence))
                    .appText(13)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
    }

    private var lowConfidenceNotice: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(L10n.reviewLowConfidence)
                .appText(13)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    /// 走了降级路径（没能按人脸裁剪）时的提示。
    ///
    /// 这条路径会在两种情况下出现：照片里真的没有人脸，或者**当前环境的
    /// 人脸检测器不可用**（模拟器上就是如此）。两种情况都该如实告诉用户。
    private func degradedNotice(_ reason: EmotionAnalysisError) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.reviewDegradedTitle)
                    .appText(13, weight: .semibold)
                Text(reason.errorDescription ?? L10n.reviewDegradedFallback)
                    .appText(12)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.2).ignoresSafeArea()
            ProgressView(L10n.saving)
                .padding(20)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}
