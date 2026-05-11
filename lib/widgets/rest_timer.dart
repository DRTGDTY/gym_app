import 'dart:async';
import 'package:flutter/material.dart';

class RestTimer extends StatefulWidget {
  final int defaultSeconds;
  final VoidCallback? onComplete;

  const RestTimer({
    super.key,
    this.defaultSeconds = 120,
    this.onComplete,
  });

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.defaultSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });
        widget.onComplete?.call();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = widget.defaultSeconds;
    });
  }

  void _adjustTime(int delta) {
    setState(() {
      _remainingSeconds = (_remainingSeconds + delta).clamp(0, 600);
    });
  }

  String get _display {
    final min = _remainingSeconds ~/ 60;
    final sec = _remainingSeconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (widget.defaultSeconds == 0) return 0;
    return _remainingSeconds / widget.defaultSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('组间休息', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey[800],
                      color: _remainingSeconds <= 10 ? Colors.orange : const Color(0xFF4CAF50),
                    ),
                  ),
                  Text(_display, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => _adjustTime(-15),
                  tooltip: '-15s',
                ),
                const SizedBox(width: 8),
                if (_isRunning)
                  IconButton.filled(
                    icon: const Icon(Icons.pause),
                    onPressed: _pauseTimer,
                    style: IconButton.styleFrom(backgroundColor: Colors.orange[700]),
                  )
                else
                  IconButton.filled(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: _startTimer,
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _resetTimer,
                  tooltip: '重置',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _adjustTime(15),
                  tooltip: '+15s',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
