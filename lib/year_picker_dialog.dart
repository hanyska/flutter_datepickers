import 'package:flutter/material.dart';
import 'package:flutter_datepickers/src/YearSelector.dart';
import 'package:flutter_datepickers/src/common.dart';
import 'package:flutter_datepickers/src/locale_utils.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class YearPickerDialog extends StatefulWidget {
  final DateTime? initialDate, firstDate, lastDate;
  final MaterialLocalizations localizations;
  final Locale? locale;

  const YearPickerDialog({
    Key? key,
    required this.initialDate,
    required this.localizations,
    this.firstDate,
    this.lastDate,
    this.locale,
  }) : super(key: key);

  @override
  _YearPickerDialogState createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<YearPickerDialog> {
  final GlobalKey<YearSelectorState> _yearSelectorState = new GlobalKey();

  PublishSubject<UpDownPageLimit>? _upDownPageLimitPublishSubject;
  PublishSubject<UpDownButtonEnableState>? _upDownButtonEnableStatePublishSubject;

  Widget? _selector;
  DateTime? selectedDate, _firstDate, _lastDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime(widget.initialDate!.year, widget.initialDate!.month);
    if (widget.firstDate != null)
      _firstDate = DateTime(widget.firstDate!.year, widget.firstDate!.month);
    if (widget.lastDate != null)
      _lastDate = DateTime(widget.lastDate!.year, widget.lastDate!.month);

    _upDownPageLimitPublishSubject = new PublishSubject();
    _upDownButtonEnableStatePublishSubject = new PublishSubject();

    setYearSelector();
  }

  void setYearSelector() {
    _selector = new YearSelector(
      key: _yearSelectorState,
      initialDate: selectedDate!,
      firstDate: _firstDate,
      lastDate: _lastDate,
      onYearSelected: _onYearSelected,
      upDownPageLimitPublishSubject: _upDownPageLimitPublishSubject!,
      upDownButtonEnableStatePublishSubject: _upDownButtonEnableStatePublishSubject!,
    );
  }

  void dispose() {
    _upDownPageLimitPublishSubject?.close();
    _upDownButtonEnableStatePublishSubject?.close();
    super.dispose();
  }

  void _onYearSelected(final int year) => setState(() {
    selectedDate = DateTime(year, 1, 1);
    setYearSelector();
  });

  void _onUpButtonPressed() => _yearSelectorState.currentState!.goUp();

  void _onDownButtonPressed() => _yearSelectorState.currentState!.goDown();

  Widget buildButtonBar(BuildContext context,) {
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
    return Material(
      color: theme.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${DateFormat.y(locale).format(selectedDate!)}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                new StreamBuilder<UpDownPageLimit>(
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
                        onPressed:
                        snapshot.data!.upState ? _onUpButtonPressed : null,
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
          transitionBuilder: (Widget child, Animation<double> animation) =>
              ScaleTransition(child: child, scale: animation),
          child: _selector,
        ),
      ),
    );
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
    );
    return Theme(
      data:
      Theme.of(context).copyWith(dialogBackgroundColor: Colors.transparent),
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
    );
  }
}