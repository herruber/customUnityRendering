using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class LoadManager : Manager
{

    public static LoadManager loadManager;

    public void InitSequence()
    {
    }

    private void Awake()
    {
        loadManager = this;
    }

    // Start is called before the first frame update
    void Start()
    {
      
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
