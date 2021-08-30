import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_datepickers/flutter_datepickers.dart';
import 'package:flutter_datepickers/src/common.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class Selector extends StatefulWidget {
  final ValueChanged<DateTime> onSelected;
  final DateTime selectedDate;
  final DateTime? firstDate, lastDate;
  final PublishSubject<UpDownPageLimit> upDownPageLimitPublishSubject;
  final PublishSubject<UpDownButtonEnableState> upDownButtonEnableStatePublishSubject;
  final Locale? locale;
  final FlutterDatePickersType type;

  const Selector({
    Key? key,
    required this.selectedDate,
    required this.onSelected,
    required this.upDownPageLimitPublishSubject,
    required this.upDownButtonEnableStatePublishSubject,
    this.firstDate,
    this.lastDate,
    this.locale,
    this.type = FlutterDatePickersType.MONTH
  }) : super(key: key);
  @override
  State<StatefulWidget> createState() => SelectorState();
}

class SelectorState extends State<Selector> {
  late PageController _pageController;
  String _locale = ui.window.locale.languageCode;

  bool get _isMonth => widget.type == FlutterDatePickersType.MONTH;

  @override
  void initState() {
    _locale = widget.locale?.languageCode ?? ui.window.locale.languageCode;

    int _initialPage = widget.firstDate == null
      ? widget.selectedDate.year
      : widget.selectedDate.year - widget.firstDate!.year;
    if (!_isMonth)
      _initialPage = (_initialPage / 12).floor();

    _pageController = new PageController(initialPage: _initialPage);
    _onPageChange(_initialPage);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      physics: const AlwaysScrollableScrollPhysics(),
      onPageChanged: _onPageChange,
      itemCount: _pageCount,
      itemBuilder: _yearGridBuilder,
    );
  }

  Widget _yearGridBuilder(final BuildContext context, final int page) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(8.0),
      crossAxisCount: 4,
      children: List<Widget>
        .generate(12, (int index) => _getButton(
          _isMonth
            ? DateTime(widget.firstDate != null ? widget.firstDate!.year + page : page, index + 1)
            : DateTime(widget.firstDate != null ? widget.firstDate!.year + page * 12 + index : 0),
        )).toList(growable: false),
    );
  }

  Widget _getButton(final DateTime date) {
    final bool isEnabled = _isEnabled(date, isYealy: !_isMonth);
    bool _isSelected = _isMonth
      ? date.month == widget.selectedDate.month && date.year == widget.selectedDate.year
      : date.year == widget.selectedDate.year;

    return TextButton(
      onPressed: isEnabled
          ? () => widget.onSelected(date)
          : null,
      style: TextButton.styleFrom(
        backgroundColor: _isSelected
          ? Theme.of(context).accentColor
          : null,
        primary: _isSelected
          ? Theme.of(context).accentTextTheme.button!.color
          : date.year == DateTime.now().year && (_isMonth ? date.month == DateTime.now().month : true)
            ? Theme.of(context).accentColor
            : Theme.of(context).textTheme.button!.color,
      ),
      child: Text(DateFormat(_isMonth ? 'MMM' : 'y', _locale).format(date)),
    );
  }

  void _onPageChange(final int page) {
    int _page = _isMonth ? page : (page * 12);
    int _upLimit = widget.firstDate != null
      ? widget.firstDate!.year + _page
      : _page;

    int _downLimit = _isMonth
      ? 0
      : widget.firstDate != null
        ? widget.firstDate!.year + page * 12 + 11
        : page * 12 + 11;

    widget.upDownPageLimitPublishSubject.add(UpDownPageLimit(_upLimit, _downLimit));
    widget.upDownButtonEnableStatePublishSubject.add(UpDownButtonEnableState(page > 0, page < _pageCount - 1));
  }

  int get _pageCount {
    if (_isMonth) {
      return _getItemCount;
    } else {
      return (_getItemCount / 12).ceil();
    }
  }

  int get _getItemCount {
    if (widget.firstDate != null && widget.lastDate != null) {
      return widget.lastDate!.year - widget.firstDate!.year + 1;
    } else if (widget.firstDate != null && widget.lastDate == null) {
      return (9999 - widget.firstDate!.year);
    } else if (widget.firstDate == null && widget.lastDate != null) {
      return widget.lastDate!.year;
    } else
      return 9999;
  }

  bool _isEnabled(DateTime date, {bool isYealy = false}) {
    if (widget.firstDate == null && widget.lastDate == null) {
      return true;
    }

    bool _isAfterFirstDate = widget.firstDate != null && (isYealy ? DateTime(widget.firstDate!.year) : DateTime(widget.firstDate!.year, widget.firstDate!.month)).compareTo(date) <= 0;
    bool _isBeforeLastDate = widget.lastDate != null && (isYealy ? DateTime(widget.lastDate!.year) : DateTime(widget.lastDate!.year, widget.lastDate!.month)).compareTo(date) >= 0;

    if (_isAfterFirstDate && _isBeforeLastDate)
      return true;

    if (widget.lastDate == null && _isAfterFirstDate)
      return true;

    if (widget.firstDate == null && _isBeforeLastDate)
      return true;

    else
      return false;
  }

  void goDown() {
    _pageController.animateToPage(
      _pageController.page!.toInt() + 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void goUp() {
    _pageController.animateToPage(
      _pageController.page!.toInt() - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }
}
