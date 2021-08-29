import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_datepickers/src/Selector.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_datepickers/src/common.dart';
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
    ThemeData? theme,
  }) async {
    final localizations = locale == null
        ? MaterialLocalizations.of(context)
        : await GlobalMaterialLocalizations.delegate.load(locale);

    return await showDialog<DateTime>(
      context: context,
      builder: (context) => PickerDialog(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        locale: locale,
        localizations: localizations,
        type: type,
        theme: theme
      )
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
  final ThemeData? theme;

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
    this.type = FlutterDatePickersType.MONTH,
    this.theme,
  }) : super(key: key);

  @override
  PickerDialogState createState() => PickerDialogState();
}

class PickerDialogState extends State<PickerDialog> {
  final GlobalKey<SelectorState> _yearSelectorState = new GlobalKey();
  final GlobalKey<SelectorState> _monthSelectorState = new GlobalKey();

  PublishSubject<UpDownPageLimit> _upDownPageLimitPublishSubject = new PublishSubject();
  PublishSubject<UpDownButtonEnableState> _upDownButtonEnableStatePublishSubject = new PublishSubject();

  late Selector _selector;
  DateTime? selectedDate, _firstDate, _lastDate;

  bool get _isMonth => widget.type == FlutterDatePickersType.MONTH;

  @override
  void initState() {
    if (widget.firstDate != null)
      _firstDate = DateTime(widget.firstDate!.year, widget.firstDate!.month);
    if (widget.lastDate != null)
      _lastDate = DateTime(widget.lastDate!.year, widget.lastDate!.month);

    selectedDate = DateTime(widget.initialDate!.year, widget.initialDate!.month);

    _setSelector(widget.type);

    super.initState();
  }

  void dispose() {
    _upDownPageLimitPublishSubject.close();
    _upDownButtonEnableStatePublishSubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = widget.theme ?? Theme.of(context);

    Widget header = buildHeader(theme);
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        buildPager(theme),
        buildButtonBar(context)
      ],
    );

    return Theme(
      data: theme,
      child: Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Builder(builder: (context) {
              if (MediaQuery.of(context).orientation == Orientation.portrait) {
                return IntrinsicWidth(
                  child: Column(
                    children: [header, content]
                  ),
                );
              }
              return IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [header, content]
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget buildButtonBar(BuildContext context) {
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

  Widget buildHeader(ThemeData theme) {
    String locale = widget.locale?.languageCode ?? ui.window.locale.languageCode;
    String _selectedDate = DateFormat(_isMonth ? 'yMMM' : 'y', locale).format(selectedDate!);

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
                new StreamBuilder<UpDownPageLimit>(
                    stream: _upDownPageLimitPublishSubject,
                    initialData: const UpDownPageLimit(0, 0),
                    builder: (_, snapshot) {
                      return _selector.type == FlutterDatePickersType.YEAR
                        ? Text.rich(
                            TextSpan(
                              style: theme.primaryTextTheme.headline5,
                              children: [
                                TextSpan(text: '${DateFormat.y(locale).format(DateTime(snapshot.data!.upLimit))}'),
                                TextSpan(text: '-'),
                                TextSpan(text: '${DateFormat.y(locale).format(DateTime(snapshot.data!.downLimit))}'),
                              ]
                            )
                          )
                        : GestureDetector(
                            onTap: () => _setSelector(FlutterDatePickersType.YEAR),
                            child: Text(
                              '${DateFormat.y(locale).format(DateTime(snapshot.data!.upLimit))}',
                              style: theme.primaryTextTheme.headline5,
                            ),
                          );
                    },
                  ),
                new StreamBuilder<UpDownButtonEnableState>(
                  stream: _upDownButtonEnableStatePublishSubject,
                  initialData: const UpDownButtonEnableState(true, true),
                  builder: (_, snapshot) => Text.rich(
                    TextSpan(
                      children: [
                        WidgetSpan(
                          child: IconButton(
                            icon: Icon(
                              Icons.keyboard_arrow_up,
                              color: snapshot.data!.upState
                                ? theme.primaryTextTheme.headline5!.color
                                : theme.primaryTextTheme.headline5!.color!.withOpacity(0.5),
                            ),
                            onPressed: snapshot.data!.upState ? _onUpButtonPressed : null,
                          ),
                        ),
                        WidgetSpan(
                          child: IconButton(
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: snapshot.data!.downState
                                ? theme.primaryTextTheme.headline5!.color
                                : theme.primaryTextTheme.headline5!.color!.withOpacity(0.5),
                            ),
                            onPressed: snapshot.data!.downState ? _onDownButtonPressed : null,
                          ),
                        )
                      ]
                    )
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPager(ThemeData theme) {
    return SizedBox(
      height: 230.0,
      width: 300.0,
      child: Theme(
        data: theme.copyWith(
          textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
              padding: MaterialStateProperty.all(EdgeInsets.all(2.0)),
              shape: MaterialStateProperty.all(CircleBorder()),
            ),
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

  void _setSelector(FlutterDatePickersType type) {
    bool _isMonth = type == FlutterDatePickersType.MONTH;

    setState(() {
      _selector = new Selector(
        key: _isMonth ? _monthSelectorState : _yearSelectorState,
        selectedDate: selectedDate!,
        firstDate: _firstDate,
        lastDate: _lastDate,
        onSelected: _isMonth ? _onMonthSelected : _onYearSelected,
        locale: widget.locale,
        upDownPageLimitPublishSubject: _upDownPageLimitPublishSubject,
        upDownButtonEnableStatePublishSubject: _upDownButtonEnableStatePublishSubject,
        type: type,
      );
    });
  }


  void _onYearSelected(final DateTime date) {
    setState(() => selectedDate = DateTime(date.year, 1, 1));
    _setSelector(widget.type);
  }

  void _onMonthSelected(final DateTime date) {
    setState(() => selectedDate = date);
    _setSelector(FlutterDatePickersType.MONTH);
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