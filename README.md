# AppUpdateCheck

# Check your current app version has app store version :-



	AppVersionCheckManager.shared.showUpdateView { status in
	    if status {
	    	/*
			your app version is not latest version.
			you are using older version.
		*/
		
		// do Something.
	    } else {
	    	// your current app is the latest version of this app
		
	    }
	}

