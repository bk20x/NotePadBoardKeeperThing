type
  WidgetId* = distinct uint32
  
  WidgetObj* = object
    parent*: Widget

  Widget* = ref WidgetObj


