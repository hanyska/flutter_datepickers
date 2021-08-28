import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_datepickers/src/Selector.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_datepickers/src/common.dart';
import 'package:flutter_datepickers/src/locale_utils.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

enum FlutterDatePickersType { MONTH, YEAR }

class FlutterDatepickers {
  static Future<DateTime?> showPicker({
    required BuildContext context,
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    Locale? locale,
    FlutterDatePickersType type = FlutterDatePickersType.MONTH,
    Color? backgroundColor,
    Color? headerTextColor,
    Color? selectedTextColor,
    Color? selectedButtonColor,
    Color? nowTextColor,
  }) async {
    final localizations = locale == null
        ? MaterialLocalizations.of(context)
        : await GlobalMaterialLocalizations.delegate.load(locale);

    return await showDialog<DateTime>(
      context: context,
      builder: (context) {
        switch(type) {
          case FlutterDatePickersType.MONTH:
            return PickerDialog(
              initialDate: initialDate,
              firstDate: firstDate,
              lastDate: lastDate,
              locale: locale,
              localizations: localizations,
              type: FlutterDatePickersType.MONTH,
            );
          case FlutterDatePickersType.YEAR:
            return PickerDialog(
              initialDate: initialDate,
              firstDate: firstDate,
              lastDate: lastDate,
              locale: locale,
              localizations: localizations,
              type: FlutterDatePickersType.YEAR,
              backgroundColor: backgroundColor,
              headerTextColor: headerTextColor,
              selectedTextColor: selectedTextColor,
              selectedButtonColor: selectedButtonColor,
              nowTextColor: nowTextColor,
            );
        }
      },
    );
  }
}


class PickerDialog extends StatefulWidget {
  final DateTime? initialDate, firstDate, lastDate;
  final MaterialLocalizations localizations;
  final Locale? locale;
  final Color? backgroundColor;
  final Color? headerTextColor;
  final Color? selectedTextColor;
  final Color? selectedButtonColor;
  final Color? nowTextColor;
  final FlutterDatePickersType type;

  const PickerDialog({
    Key? key,
    required this.initialDate,
    required this.localizations,
    this.firstDate,
    this.lastDate,
    this.locale,
    this.backgroundColor,
    this.headerTextColor,
    this.selectedTextColor,
    this.selectedButtonColor,
    this.nowTextColor,
    this.type = FlutterDatePickersType.MONTH
  }) : super(key: key);

  @override
  PickerDialogState createState() => PickerDialogState();
}

class PickerDialogState extends State<PickerDialog> {
  final GlobalKey<SelectorState> _yearSelectorState = new GlobalKey();
  final GlobalKey<SelectorState> _monthSelectorState = new GlobalKey();

  PublishSubject<UpDownPageLimit> _upDownPageLimitPublishSubject = new PublishSubject();
  PublishSubject<UpDownButtonEnableState> _upDownButtonEnableStatePublishSubject = new PublishSubject();

  Selector? _selector;
  DateTime? selectedDate, _firstDate, _lastDate;

  bool get _isMonth => widget.type == FlutterDatePickersType.MONTH;

  @override
  void initState() {
    if (widget.firstDate != null)
      _firstDate = DateTime(widget.firstDate!.year, widget.firstDate!.month);
    if (widget.lastDate != null)
      _lastDate = DateTime(widget.lastDate!.year, widget.lastDate!.month);

    selectedDate = DateTime(widget.initialDate!.year, widget.initialDate!.month);

    widget.type == FlutterDatePickersType.YEAR
        ?  setYearSelector()
        : _setMonthSelector();

    super.initState();
  }

  void _setMonthSelector([DateTime? _selectedDate]) {
    setState(() {
      _selector = new Selector(
        key: _monthSelectorState,
        // openDate: _openDate ?? selectedDate!,
        selectedDate: _selectedDate ?? selectedDate!,
        upDownPageLimitPublishSubject: _upDownPageLimitPublishSubject,
        upDownButtonEnableStatePublishSubject: _upDownButtonEnableStatePublishSubject,
        firstDate: _firstDate,
        lastDate: _lastDate,
        onSelected: _onMonthSelected,
        locale: widget.locale,
      );
    });
  }

  void dispose() {
    _upDownPageLimitPublishSubject.close();
    _upDownButtonEnableStatePublishSubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = getLocale(context, selectedLocale: widget.locale);
    var header = buildHeader(theme, locale);
    var pager = buildPager(theme, locale);
    var content = Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [pager, buildButtonBar(context)],
      ),
      color: theme.dialogBackgroundColor,
    );
    return Theme(
      data: Theme.of(context).copyWith(dialogBackgroundColor: Colors.transparent),
      child: Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Builder(builder: (context) {
              if (MediaQuery.of(context).orientation == Orientation.portrait) {
                return IntrinsicWidth(
                  child: Column(children: [header, content]),
                );
              }
              return IntrinsicHeight(
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [header, content]),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget buildButtonBar(
      BuildContext context,
      ) {
    return ButtonBar(
      children: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(widget.localizations.cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, selectedDate),
          child: Text(widget.localizations.okButtonLabel),
        )
      ],
    );
  }

  Widget buildHeader(ThemeData theme, String locale) {
    String _selectedDate = _isMonth
        ? DateFormat.yMMM(locale).format(selectedDate!)
        : DateFormat.y(locale).format(selectedDate!);

    return Material(
      color: theme.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _selectedDate,
              style: theme.primaryTextTheme.subtitle1,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _selector!.type == FlutterDatePickersType.MONTH
                    ? GestureDetector(
                  onTap: _onSelectYear,
                  child: new StreamBuilder<UpDownPageLimit>(
                    stream: _upDownPageLimitPublishSubject,
                    initialData: const UpDownPageLimit(0, 0),
                    builder: (_, snapshot) => Text(
                      '${DateFormat.y(locale).format(DateTime(snapshot.data!.upLimit))}',
                      style: theme.primaryTextTheme.headline5,
                    ),
                  ),
                )
                    : new StreamBuilder<UpDownPageLimit>(
                  stream: _upDownPageLimitPublishSubject,
                  initialData: const UpDownPageLimit(0, 0),
                  builder: (_, snapshot) => Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${DateFormat.y(locale).format(DateTime(snapshot.data!.upLimit))}',
                        style: theme.primaryTextTheme.headline5,
                      ),
                      Text(
                        '-',
                        style: theme.primaryTextTheme.headline5,
                      ),
                      Text(
                        '${DateFormat.y(locale).format(DateTime(snapshot.data!.downLimit))}',
                        style: theme.primaryTextTheme.headline5,
                      ),
                    ],
                  ),
                ),
                new StreamBuilder<UpDownButtonEnableState>(
                  stream: _upDownButtonEnableStatePublishSubject,
                  initialData: const UpDownButtonEnableState(true, true),
                  builder: (_, snapshot) => Row(
                    children: <Widget>[
                      IconButton(
                        icon: Icon(
                          Icons.keyboard_arrow_up,
                          color: snapshot.data!.upState
                              ? theme.primaryIconTheme.color
                              : theme.primaryIconTheme.color!.withOpacity(0.5),
                        ),
                        onPressed: snapshot.data!.upState
                            ? _onUpButtonPressed
                            : null,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: snapshot.data!.downState
                              ? theme.primaryIconTheme.color
                              : theme.primaryIconTheme.color!.withOpacity(0.5),
                        ),
                        onPressed: snapshot.data!.downState
                            ? _onDownButtonPressed
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPager(ThemeData theme, String locale) {
    return SizedBox(
      height: 230.0,
      width: 300.0,
      child: Theme(
        data: theme.copyWith(
          buttonTheme: ButtonThemeData(
            padding: EdgeInsets.all(2.0),
            shape: CircleBorder(),
            minWidth: 4.0,
          ),
        ),
        child: new AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) => ScaleTransition(child: child, scale: animation),
          child: _selector,
        ),
      ),
    );
  }

  void _onSelectYear() => setState(() => _selector = new Selector(
    key: _yearSelectorState,
    selectedDate: selectedDate!,
    firstDate: _firstDate,
    lastDate: _lastDate,
    onSelected: _onYearSelected,
    type: FlutterDatePickersType.YEAR,
    upDownPageLimitPublishSubject: _upDownPageLimitPublishSubject,
    upDownButtonEnableStatePublishSubject: _upDownButtonEnableStatePublishSubject,
  ));

  void setYearSelector() {
    setState(() {
      _selector = new Selector(
        key: _yearSelectorState,
        selectedDate: selectedDate!,
        firstDate: _firstDate,
        lastDate: _lastDate,
        onSelected: _onYearSelected,
        upDownPageLimitPublishSubject: _upDownPageLimitPublishSubject,
        upDownButtonEnableStatePublishSubject: _upDownButtonEnableStatePublishSubject,
        backgroundColor: widget.backgroundColor,
        selectedButtonColor: widget.selectedButtonColor,
        selectedTextColor: widget.selectedTextColor,
        nowTextColor: widget.nowTextColor,
        type: FlutterDatePickersType.YEAR,
      );
    });
  }

  void _onYearSelected(final DateTime date) {
    if (_isMonth) {
      _setMonthSelector(DateTime(date.year));
    } else {
      setState(() => selectedDate = DateTime(date.year, 1, 1));
      setYearSelector();
    }
  }

  void _onMonthSelected(final DateTime date) {
    setState(() => selectedDate = date);
    _setMonthSelector();
  }

  void _onUpButtonPressed() {
    if (_yearSelectorState.currentState != null) {
      _yearSelectorState.currentState!.goUp();
    } else {
      _monthSelectorState.currentState!.goUp();
    }
  }

  void _onDownButtonPressed() {
    if (_yearSelectorState.currentState != null) {
      _yearSelectorState.currentState!.goDown();
    } else {
      _monthSelectorState.currentState!.goDown();
    }
  }
}