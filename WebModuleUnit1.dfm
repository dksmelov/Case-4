object WebModule1: TWebModule1
  OldCreateOrder = False
  Actions = <
    item
      Default = True
      Name = 'DefaultAction'
      PathInfo = '/'
      OnAction = WebModule1DefaultAction
    end
    item
      Name = 'ToursAction'
      PathInfo = '/tours'
      OnAction = WebModule1ToursAction
    end
    item
      Name = 'OrderAction'
      PathInfo = '/order'
      OnAction = WebModule1OrderAction
    end>
  Height = 230
  Width = 415
end
