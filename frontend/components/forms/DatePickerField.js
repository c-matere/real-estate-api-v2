import dayjs from 'dayjs';

<DesktopDatePicker
  label="Due Date"
  value={values.dueDate ? dayjs(values.dueDate) : null}
  onChange={(newValue) => setFieldValue('dueDate', newValue ? newValue.toISOString() : null)}
  slotProps={{
    textField: {
      fullWidth: true,
      variant: 'outlined',
    },
  }}
/> 