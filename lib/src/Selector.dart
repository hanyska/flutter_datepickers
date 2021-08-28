import 'package:flutter/material.dart';
import 'package:flutter_datepickers/src/common.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

import 'locale_utils.dart';

enum SelectorType {
  MONTH,
  YEAR
}

class Selector extends StatefulWidget {
  final ValueChanged<DateTime> onSelected;
  final DateTime? openDate, selectedDate, firstDate, lastDate;
  final PublishSubject<UpDownPageLimit> upDownPageLimitPublishSubject;
  final PublishSubject<UpDownButtonEnableState> upDownButtonEnableStatePublishSubject;
  final Locale? locale;
  final Color? backgroundColor;
  final Color? selectedTextColor;
  final Color? selectedButtonColor;
  final Color? nowTextColor;
  final SelectorType type;

  const Selector({
    Key? key,
    required this.openDate,
    required DateTime this.selectedDate,
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
    this.type = SelectorType.MONTH
  }) : super(key: key);
  @override
  State<StatefulWidget> createState() => SelectorState();
}

class SelectorState extends State<Selector> {
  PageController? _pageController;

  bool get _isMonth => widget.type == SelectorType.MONTH;

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
        .generate(12, (int index) {
          return _isMonth
          ? _getMonthButton(
              DateTime(widget.firstDate != null ? widget.firstDate!.year + page : page, index + 1),
              getLocale(context, selectedLocale: widget.locale)
            )
          : _getYearButton(
              DateTime(widget.firstDate == null ? 0 : widget.firstDate!.year + page * 12 + index),
              getLocale(context, selectedLocale: widget.locale)
          );
        }).toList(growable: false),
    );
  }

  Widget _getMonthButton(final DateTime date, final String locale) {
    final bool isEnabled = _isEnabled(date);
    return FlatButton(
      onPressed: isEnabled
          ? () => widget.onSelected(DateTime(date.year, date.month))
          : null,
      color: date.month == widget.selectedDate!.month &&
          date.year == widget.selectedDate!.year
          ? Theme.of(context).accentColor
          : null,
      textColor: date.month == widget.selectedDate!.month &&
          date.year == widget.selectedDate!.year
          ? Theme.of(context).accentTextTheme.button!.color
          : date.month == DateTime.now().month &&
          date.year == DateTime.now().year
          ? Theme.of(context).accentColor
          : null,
      child: Text(DateFormat.MMM(locale).format(date)),
    );
  }

  Widget _getYearButton(final DateTime date, final String locale) {
    final bool isEnabled = _isEnabled(date, isYealy: true);

    return TextButton(
      onPressed: isEnabled
          ? () => widget.onSelected(date)
          : null,
      style: TextButton.styleFrom(
          shape: CircleBorder(),
          backgroundColor: date.year == widget.selectedDate!.year
              ? widget.selectedButtonColor ?? Theme.of(context).accentColor
              : null,
          primary: date.year == widget.selectedDate!.year
              ? widget.selectedTextColor ?? Theme.of(context).accentTextTheme.button!.color
              : date.year == DateTime.now().year
              ? widget.nowTextColor ?? Theme.of(context).accentColor
              : null
      ),
      child: Text(DateFormat.y(locale).format(date),
      ),
    );
  }

  void _onPageChange(final int page) {
    if (_isMonth) {
      widget.upDownPageLimitPublishSubject.add(
        new UpDownPageLimit(
          widget.firstDate != null ? widget.firstDate!.year + page : page,
          0,
        ),
      );
      widget.upDownButtonEnableStatePublishSubject.add(
        new UpDownButtonEnableState(page > 0, page < _getPageCount() - 1),
      );
    } else {
      widget.upDownPageLimitPublishSubject.add(new UpDownPageLimit(
          widget.firstDate == null
              ? page * 12
              : widget.firstDate!.year + page * 12,
          widget.firstDate == null
              ? page * 12 + 11
              : widget.firstDate!.year + page * 12 + 11));
      if (page == 0 || page == _getPageCount() - 1) {
        widget.upDownButtonEnableStatePublishSubject.add(
          new UpDownButtonEnableState(page > 0, page < _getPageCount() - 1),
        );
      }
    }
  }

  int _getPageCount() {
    if (_isMonth) {
      if (widget.firstDate != null && widget.lastDate != null) {
        return widget.lastDate!.year - widget.firstDate!.year + 1;
      } else if (widget.firstDate != null && widget.lastDate == null) {
        return 9999 - widget.firstDate!.year;
      } else if (widget.firstDate == null && widget.lastDate != null) {
        return widget.lastDate!.year + 1;
      } else
        return 9999;
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

  @override
  void initState() {
    if (_isMonth) {
      _pageController = new PageController(
        initialPage: widget.firstDate == null
          ? widget.openDate!.year
          : widget.openDate!.year - widget.firstDate!.year);
    } else {
      _pageController = new PageController(
        initialPage: widget.firstDate == null
          ? (widget.selectedDate!.year / 12).floor()
          : ((widget.selectedDate!.year - widget.firstDate!.year) / 12).floor());
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
