function yes = isViolationTrial(vr)

  yes   = (vr.timeElapsed - vr.logger.trialStart() > vr.maxTrialDuration) ...
        ;

end
