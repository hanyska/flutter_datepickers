import 'package:flutter/material.dart';
import 'package:flutter_datepickers/flutter_datepickers.dart';
import 'package:flutter_datepickers/src/common.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

import 'locale_utils.dart';

class Selector extends StatefulWidget {
  final ValueChanged<DateTime> onSelected;
  final DateTime selectedDate;
  final DateTime? firstDate, lastDate;
  final PublishSubject<UpDownPageLimit> upDownPageLimitPublishSubject;
  final PublishSubject<UpDownButtonEnableState> upDownButtonEnableStatePublishSubject;
  final Locale? locale;
  final Color? backgroundColor;
  final Color? selectedTextColor;
  final Color? selectedButtonColor;
  final Color? nowTextColor;
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
    this.backgroundColor,
    this.selectedTextColor,
    this.selectedButtonColor,
    this.nowTextColor,
    this.type = FlutterDatePickersType.MONTH
  }) : super(key: key);
  @override
  State<StatefulWidget> createState() => SelectorState();
}

class SelectorState extends State<Selector> {
  PageController? _pageController;

  bool get _isMonth => widget.type == FlutterDatePickersType.MONTH;

  @override
  void initState() {
    if (_isMonth) {
      _pageController = new PageController(
          initialPage: widget.firstDate == null
              ? widget.selectedDate.year
              : widget.selectedDate.year - widget.firstDate!.year);
    } else {
      _pageController = new PageController(
          initialPage: widget.firstDate == null
              ? (widget.selectedDate.year / 12).floor()
              : ((widget.selectedDate.year - widget.firstDate!.year) / 12).floor());
    }


    new Future.delayed(Duration.zero, () {
      if (_isMonth) {
        widget.upDownPageLimitPublishSubject.add(
          new UpDownPageLimit(
            widget.firstDate == null
                ? _pageController!.page!.toInt()
                : widget.firstDate!.year + _pageController!.page!.toInt(),
            0,
          ),
        );
      } else {
        widget.upDownPageLimitPublishSubject.add(new UpDownPageLimit(
          widget.firstDate == null
              ? _pageController!.page!.toInt() * 12
              : widget.firstDate!.year + _pageController!.page!.toInt() * 12,
          widget.firstDate == null
              ? _pageController!.page!.toInt() * 12 + 11
              : widget.firstDate!.year + _pageController!.page!.toInt() * 12 + 11,
        ));
      }


      widget.upDownButtonEnableStatePublishSubject.add(
        new UpDownButtonEnableState(
            _pageController!.page!.toInt() > 0,
            _pageController!.page!.toInt() < _getPageCount() - 1
        ),
      );
    });

    super.initState();
  }

  @override
  void dispose() {
    _pageController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      physics: const AlwaysScrollableScrollPhysics(),
      onPageChanged: _onPageChange,
      itemCount: _getPageCount(),
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
          getLocale(context, selectedLocale: widget.locale)
        )).toList(growable: false),
    );
  }

  Widget _getButton(final DateTime date, final String locale) {
    final bool isEnabled = _isEnabled(date, isYealy: !_isMonth);
    bool _isSelected = _isMonth
      ? date.month == widget.selectedDate.month && date.year == widget.selectedDate.year
      : date.year == widget.selectedDate.year;

    return TextButton(
      onPressed: isEnabled
          ? () => widget.onSelected(date)
          : null,
      style: TextButton.styleFrom(
        shape: CircleBorder(),
        backgroundColor: _isSelected
          ? widget.selectedButtonColor ?? Theme.of(context).accentColor
          : null,
        primary: _isSelected
          ? widget.selectedTextColor ?? Theme.of(context).accentTextTheme.button!.color
          : date.year == DateTime.now().year && (_isMonth ? date.month == DateTime.now().month : true)
            ? widget.nowTextColor ?? Theme.of(context).accentColor
            : null,
      ),
      child: Text(DateFormat(_isMonth ? 'MMM' : 'y', locale).format(date)),
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
    widget.upDownButtonEnableStatePublishSubject.add(UpDownButtonEnableState(page > 0, page < _getPageCount() - 1));
  }

  int _getPageCount() {
    if (_isMonth) {
      return _getItemCount;
    } else {
      if (widget.firstDate != null && widget.lastDate != null) {
        if (widget.lastDate!.year - widget.firstDate!.year <= 12)
          return 1;
        else
          return ((widget.lastDate!.year - widget.firstDate!.year + 1) / 12).ceil();
      } else if (widget.firstDate != null && widget.lastDate == null) {
        return (_getItemCount / 12).ceil();
      } else if (widget.firstDate == null && widget.lastDate != null) {
        return (_getItemCount / 12).ceil();
      } else
        return (9999 / 12).ceil();
    }
  }

  int get _getItemCount{
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

    bool _isAfterFirstDate = widget.firstDate != null && DateTime(isYealy ? widget.firstDate!.year : widget.firstDate!.year).compareTo(date) <= 0;
    bool _isBeforeLastDate = widget.lastDate != null && DateTime(isYealy ? widget.lastDate!.year : widget.lastDate!.year).compareTo(date) >= 0;

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
    _pageController!.animateToPage(
      _pageController!.page!.toInt() + 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void goUp() {
    _pageController!.animateToPage(
      _pageController!.page!.toInt() - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }
}
