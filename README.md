Pushover4D
===

[Pushover](https://pushover.net) for Delphi library.


How to
---
```pascal
uses
  ..., Rac.Pushover, ...

var
  po: TPushover;
  msg: TPushoverMessage;
  title, content: string;
begin
  // Create TPushover object
  po := TPushover.Create;
  try

    // Setup po object:
    // po.UserKey might be User Key or GroupKey
    po.ApiKey  := 'MY_API_KEY'; // It's necessary
    po.UserKey := 'MY_USER_OR_GROUP_KEY'; // It's necessary
    // Would be also nice to assign some notifications to po object

    // Setup content:
    title   := 'Example title'; // It isn't necessary and can be empty
    content := 'Example content'; // It's necessary

    // Create message:
    msg := TPushoverMessage(title, content); // Create message
    try
      // If you want different keys than in po object, you can
      // put it here:
      // msg.UserKey := 'MY_OTHER_USER_OR_GROUP_KEY';
      // ApiKey and UserKey are assigned to the message automatically only when are empty. So if you fill it manually it will not be overwritten.

      // Send message:
      po.Send(msg);
    finally
      msg.DisposeOf;
    end;
  finally
    po.DisposeOf;
  end;
end;
```


Examples
---
Of course example application is attached so you can test library immediatelly. Just rename file keys.inc.example to keys.inc, fill constants in this file and next build application. That's it.


What is not supported
---
  * Get user limits API (user limits are returned in every successful response and can be readed in TPushover.OnGetLimits event, so i'm not convicted it's necessary to support this function)
  * Subscriptions (simply because i don't use it)


ToDo
---
  * Something's wrong with [Message Time](https://pushover.net/api#timestamp) - i have to figure out what's wrong... someday

Everything else should works fine.


BTW
---
To compile Rac.Pushover, it's necessary to have Rac.Json.Reader. You can use version from this repository or from [oryginal repository](https://github.com/raccoon-dev/JsonReader).
