class DownloadItem {
  DownloadItem({
    required this.id,
    required this.url,
    required this.status,
    required this.progress,
    this.file,
    this.error,
  });

  final String id;
  final String url;
  final String status;
  final int progress;
  final String? file;
  final String? error;

  DownloadItem copyWith({
    String? status,
    int? progress,
    String? file,
    String? error,
  }) {
    return DownloadItem(
      id: id,
      url: url,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      file: file ?? this.file,
      error: error ?? this.error,
    );
  }

  factory DownloadItem.fromEvent(Map<dynamic, dynamic> map) {
    return DownloadItem(
      id: (map['id'] as String?) ?? DateTime.now().microsecondsSinceEpoch.toString(),
      url: (map['url'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'running',
      progress: (map['progress'] as int?) ?? 0,
      file: map['file'] as String?,
      error: map['error'] as String?,
    );
  }
}
