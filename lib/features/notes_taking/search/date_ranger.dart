import 'package:flutter/material.dart';

class CustomDateRangePicker extends StatefulWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final ThemeData theme;
  final Function(DateTimeRange) onDateRangeSelected;

  const CustomDateRangePicker({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.theme,
    required this.onDateRangeSelected,
  });

  @override
  State<CustomDateRangePicker> createState() => CustomDateRangePickerState();
}

class CustomDateRangePickerState extends State<CustomDateRangePicker>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  DateTime _currentMonth = DateTime.now();
  bool _isSelectingEndDate = false;

  @override
  void initState() {
    super.initState();
    _selectedFromDate = widget.fromDate;
    _selectedToDate = widget.toDate;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectDate(DateTime date) {
    // Selecting start date (no start yet or previous range completed)
    if (_selectedFromDate == null || _selectedToDate != null || !_isSelectingEndDate) {
      setState(() {
        _selectedFromDate = date;
        _selectedToDate = null;
        _isSelectingEndDate = true;
      });
      return;
    }
    // Selecting end date
    if (date.isBefore(_selectedFromDate!)) {
      final prevStart = _selectedFromDate!;
      setState(() {
        _selectedFromDate = date;
        _selectedToDate = prevStart;
        _isSelectingEndDate = false;
      });
    } else {
      setState(() {
        _selectedToDate = date;
        _isSelectingEndDate = false;
      });
    }
  }

  void _confirmSelection() {
    if (_selectedFromDate != null && _selectedToDate != null) {
      widget.onDateRangeSelected(
        DateTimeRange(start: _selectedFromDate!, end: _selectedToDate!),
      );
      Navigator.pop(context);
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedFromDate = null;
      _selectedToDate = null;
      _isSelectingEndDate = false;
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  bool _isDateInRange(DateTime date) {
    if (_selectedFromDate == null || _selectedToDate == null) return false;
    return date.isAfter(_selectedFromDate!.subtract(const Duration(days: 1))) &&
        date.isBefore(_selectedToDate!.add(const Duration(days: 1)));
  }

  bool _isDateSelected(DateTime date) {
    if (_selectedFromDate == null && _selectedToDate == null) return false;
    if (_selectedFromDate != null && _isSameDay(date, _selectedFromDate!)) {
      return true;
    }
    if (_selectedToDate != null && _isSameDay(date, _selectedToDate!)) {
      return true;
    }
    return false;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: widget.theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDragHandle(),
              _buildHeader(),
              _buildDateRangeDisplay(),
              _buildCalendarHeader(),
              Expanded(child: _buildCalendar()),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.8),
              size: 24,
            ),
            style: IconButton.styleFrom(
              backgroundColor: widget.theme.colorScheme.surface,
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Select Date Range',
            style: widget.theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: widget.theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _clearSelection,
            icon: Icon(
              Icons.refresh,
              color: widget.theme.colorScheme.primary,
              size: 22,
            ),
            tooltip: 'Clear selection',
            style: IconButton.styleFrom(
              backgroundColor:
                  widget.theme.colorScheme.primary.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeDisplay() {
    final fromText = _selectedFromDate != null
        ? '${_selectedFromDate!.day} ${_getMonthShortName(_selectedFromDate!.month)} ${_selectedFromDate!.year}'
        : 'Start Date';
    final toText = _selectedToDate != null
        ? '${_selectedToDate!.day} ${_getMonthShortName(_selectedToDate!.month)} ${_selectedToDate!.year}'
        : 'End Date';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDateChip(
              label: 'From',
              date: fromText,
              isSelected: _selectedFromDate != null,
              isActive: !_isSelectingEndDate,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.arrow_forward,
              color: widget.theme.colorScheme.primary.withValues(alpha: 0.6),
              size: 18,
            ),
          ),
          Expanded(
            child: _buildDateChip(
              label: 'To',
              date: toText,
              isSelected: _selectedToDate != null,
              isActive: _isSelectingEndDate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip({
    required String label,
    required String date,
    required bool isSelected,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isActive
            ? widget.theme.colorScheme.primary.withValues(alpha: 0.12)
            : isSelected
                ? widget.theme.colorScheme.primary.withValues(alpha: 0.05)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? widget.theme.colorScheme.primary
                  : widget.theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: Icon(
              Icons.chevron_left,
              color: widget.theme.colorScheme.primary,
              size: 28,
            ),
            style: IconButton.styleFrom(
              backgroundColor:
                  widget.theme.colorScheme.primary.withValues(alpha: 0.08),
              padding: const EdgeInsets.all(8),
            ),
          ),
          Text(
            '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
            style: widget.theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: widget.theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: Icon(
              Icons.chevron_right,
              color: widget.theme.colorScheme.primary,
              size: 28,
            ),
            style: IconButton.styleFrom(
              backgroundColor:
                  widget.theme.colorScheme.primary.withValues(alpha: 0.08),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Days of week header
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            widget.theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Calendar grid
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: 42, // 6 weeks * 7 days
              itemBuilder: (context, index) {
                final dayOffset = index - (firstWeekday - 1);
                final day = dayOffset + 1;

                if (day < 1 || day > daysInMonth) {
                  return Container(); // Empty space
                }

                final date =
                    DateTime(_currentMonth.year, _currentMonth.month, day);
                final isInRange = _isDateInRange(date);
                final isSelected = _isDateSelected(date);
                final isToday = _isSameDay(date, DateTime.now());
                return GestureDetector(
                  onTap: () => _selectDate(date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? widget.theme.colorScheme.primary
                          : isInRange
                              ? widget.theme.colorScheme.primary
                                  .withValues(alpha: 0.15)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(isSelected ? 12 : 10),
                      border: isToday && !isSelected
                          ? Border.all(
                              color: widget.theme.colorScheme.primary,
                              width: 1.5,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: widget.theme.colorScheme.primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        day.toString(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? widget.theme.colorScheme.onPrimary
                              : isInRange || isToday
                                  ? widget.theme.colorScheme.primary
                                  : widget.theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final bool canConfirm =
        _selectedFromDate != null && _selectedToDate != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: widget.theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: canConfirm ? _confirmSelection : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.theme.colorScheme.primary,
                foregroundColor: widget.theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: canConfirm ? 2 : 0,
                disabledBackgroundColor:
                    widget.theme.colorScheme.primary.withValues(alpha: 0.4),
                disabledForegroundColor:
                    widget.theme.colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
              child: Text(
                'Confirm',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: widget.theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  String _getMonthShortName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
